#!/usr/bin/env python3
"""
parse_metrics.py — Parser de métricas del experimento SAFE
Uso: python3 parse_metrics.py <log_A> <log_B> [--csv salida.csv]
"""
import json, sys, csv, argparse
from collections import defaultdict

# ---------------------------------------------------------------------------
# Mapeo keyword → (táctica, técnica) ATT&CK
# ---------------------------------------------------------------------------
MITRE = [
    ("id &&",               "TA0007", "T1082"),
    ("whoami",              "TA0007", "T1082"),
    ("uname",               "TA0007", "T1082"),
    ("hostname",            "TA0007", "T1082"),
    ("ip a",                "TA0007", "T1016"),
    ("ifconfig",            "TA0007", "T1016"),
    ("ip route",            "TA0007", "T1016"),
    ("ss -tulnp",           "TA0007", "T1049"),
    ("netstat",             "TA0007", "T1049"),
    ("ps aux",              "TA0007", "T1057"),
    ("systemctl",           "TA0007", "T1007"),
    ("dpkg -l",             "TA0007", "T1518.001"),
    ("w; who",              "TA0007", "T1087.001"),
    ("last",                "TA0007", "T1087.001"),
    ("cat /etc/passwd",     "TA0006", "T1003.008"),
    ("cat /etc/shadow",     "TA0006", "T1003.008"),
    ("cat ~/.bash_history", "TA0006", "T1552.003"),
    ("cat ~/.zsh_history",  "TA0006", "T1552.003"),
    ("find /etc -name",     "TA0006", "T1552.001"),
    ("grep -r",             "TA0006", "T1552.001"),
    (".env",                "TA0006", "T1552.001"),
    ("authorized_keys",     "TA0003", "T1098.004"),
    ("crontab",             "TA0003", "T1053.003"),
    ("useradd",             "TA0003", "T1136.001"),
    ("bashrc",              "TA0003", "T1546.004"),
    ("sudo -l",             "TA0004", "T1548.003"),
    ("/etc/sudoers",        "TA0004", "T1548.003"),
    ("-perm -4000",         "TA0004", "T1548.001"),
    ("-perm -u=s",          "TA0004", "T1548.001"),
    ("uname -r",            "TA0004", "T1068"),
    ("/proc/version",       "TA0004", "T1068"),
    ("history -c",          "TA0005", "T1070.003"),
    ("HISTFILE",            "TA0005", "T1070.003"),
    ("/var/log/auth.log",   "TA0005", "T1070.002"),
    ("touch -t",            "TA0005", "T1070.006"),
    ("/tmp/sshd",           "TA0005", "T1036.005"),
    ("kworker",             "TA0005", "T1036.005"),
    ("http://10.0.0.99",    "TA0011", "T1105"),
    ("wget",                "TA0011", "T1105"),
    ("python3 -c",          "TA0002", "T1059.006"),
    ("bash -i >",           "TA0002", "T1059.004"),
    ("bash -c",             "TA0002", "T1059.004"),
    (".xmrig",              "TA0040", "T1496"),
    ("minexmr",             "TA0040", "T1496"),
    ("mysql",               "TA0009", "T1005"),
    (".pem",                "TA0009", "T1005"),
    ("id_rsa",              "TA0009", "T1005"),
    ("pg_hba.conf",         "TA0009", "T1005"),
]

LLM_TIMEOUT_MS = 60_000  # Cowrie corta la conexión al LLM a los 60 s


def load_log(path):
    with open(path) as f:
        return [json.loads(line) for line in f if line.strip()]


def group_by_session(events):
    sessions = defaultdict(list)
    for e in events:
        sessions[e["session"]].append(e)
    return sessions


def extract_session_metrics(session_events):
    commands = [e["input"] for e in session_events
                if e["eventid"] == "cowrie.command.input"]
    closed = next(
        (e for e in session_events if e["eventid"] == "cowrie.session.closed"),
        None,
    )
    duration_ms = closed["duration_ms"] if closed else None
    timedout = (duration_ms is not None and duration_ms >= LLM_TIMEOUT_MS)
    return {"commands": commands, "duration_ms": duration_ms, "timedout": timedout}


def map_mitre(input_str):
    found = set()
    for kw, tac, tec in MITRE:
        if kw in input_str:
            found.add((tac, tec))
    return found


def compute_condition_metrics(log_path):
    events = load_log(log_path)
    sessions = group_by_session(events)

    durations = []
    all_commands = []
    all_techniques = set()
    all_tactics = set()
    timedout_count = 0
    sessions_with_cmds = 0

    for sid, evts in sessions.items():
        m = extract_session_metrics(evts)
        if not m["commands"]:
            continue
        sessions_with_cmds += 1
        all_commands.extend(m["commands"])
        if m["duration_ms"] is not None:
            durations.append(m["duration_ms"])
        if m["timedout"]:
            timedout_count += 1
        for cmd in m["commands"]:
            for tac, tec in map_mitre(cmd):
                all_tactics.add(tac)
                all_techniques.add(tec)

    durations.sort()
    n = len(durations)
    p50 = durations[n // 2] if n else None
    p95 = durations[int(n * 0.95)] if n else None
    mean = int(sum(durations) / n) if n else None

    return {
        "sessions_with_cmds": sessions_with_cmds,
        "total_commands": len(all_commands),
        "cmds_per_session": len(all_commands) / sessions_with_cmds if sessions_with_cmds else 0,
        "duration_mean_ms": mean,
        "duration_p50_ms": p50,
        "duration_p95_ms": p95,
        "timedout": timedout_count,
        "stability_pct": 100 * (sessions_with_cmds - timedout_count) / sessions_with_cmds if sessions_with_cmds else 0,
        "tactics_count": len(all_tactics),
        "techniques_count": len(all_techniques),
        "tactics": sorted(all_tactics),
        "techniques": sorted(all_techniques),
    }


def print_report(metrics_a, metrics_b):
    rows = [
        ("Sesiones con comandos",    metrics_a["sessions_with_cmds"],       metrics_b["sessions_with_cmds"]),
        ("Comandos totales",         metrics_a["total_commands"],            metrics_b["total_commands"]),
        ("Cmds / sesión (media)",    f'{metrics_a["cmds_per_session"]:.1f}', f'{metrics_b["cmds_per_session"]:.1f}'),
        ("Duración media (ms)",      metrics_a["duration_mean_ms"],          metrics_b["duration_mean_ms"]),
        ("Duración p50 (ms)",        metrics_a["duration_p50_ms"],           metrics_b["duration_p50_ms"]),
        ("Duración p95 (ms)",        metrics_a["duration_p95_ms"],           metrics_b["duration_p95_ms"]),
        ("Sesiones con timeout LLM", metrics_a["timedout"],                  metrics_b["timedout"]),
        ("Estabilidad (%)",          f'{metrics_a["stability_pct"]:.1f}',    f'{metrics_b["stability_pct"]:.1f}'),
        ("Tácticas ATT&CK",          metrics_a["tactics_count"],             metrics_b["tactics_count"]),
        ("Técnicas ATT&CK",          metrics_a["techniques_count"],          metrics_b["techniques_count"]),
    ]
    w = 32
    print()
    print(f"{'Métrica':<{w}}  {'Cond. A (shell)':>18}  {'Cond. B (LLM)':>18}")
    print("-" * (w + 42))
    for label, va, vb in rows:
        print(f"{label:<{w}}  {str(va):>18}  {str(vb):>18}")
    print()
    print(f"Técnicas A: {', '.join(metrics_a['techniques'])}")
    print(f"Técnicas B: {', '.join(metrics_b['techniques'])}")
    print()


def write_csv(path, metrics_a, metrics_b):
    fields = [
        "condicion", "sessions_with_cmds", "total_commands", "cmds_per_session",
        "duration_mean_ms", "duration_p50_ms", "duration_p95_ms",
        "timedout", "stability_pct", "tactics_count", "techniques_count",
        "techniques",
    ]
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(fields)
        for label, m in [("A_shell", metrics_a), ("B_llm", metrics_b)]:
            w.writerow([
                label,
                m["sessions_with_cmds"],
                m["total_commands"],
                f'{m["cmds_per_session"]:.2f}',
                m["duration_mean_ms"],
                m["duration_p50_ms"],
                m["duration_p95_ms"],
                m["timedout"],
                f'{m["stability_pct"]:.1f}',
                m["tactics_count"],
                m["techniques_count"],
                "|".join(m["techniques"]),
            ])
    print(f"CSV exportado: {path}")


def main():
    ap = argparse.ArgumentParser(description="Parser de métricas SAFE honeypot")
    ap.add_argument("log_a", help="cowrie.json Condición A (shell)")
    ap.add_argument("log_b", help="cowrie.json Condición B (LLM)")
    ap.add_argument("--csv", metavar="FILE", help="Exportar métricas a CSV")
    args = ap.parse_args()

    print(f"Cargando {args.log_a} …")
    ma = compute_condition_metrics(args.log_a)
    print(f"Cargando {args.log_b} …")
    mb = compute_condition_metrics(args.log_b)

    print_report(ma, mb)

    if args.csv:
        write_csv(args.csv, ma, mb)


if __name__ == "__main__":
    main()
