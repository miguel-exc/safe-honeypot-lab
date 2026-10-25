# SPDX-FileCopyrightText: 2015-2026 Michel Oosterhof <michel@oosterhof.net>
#
# SPDX-License-Identifier: BSD-3-Clause

from __future__ import annotations

from twisted.conch.interfaces import ISession
from twisted.conch.ssh import session
from zope.interface import implementer

from cowrie.insults import insults
from cowrie.llm import protocol


@implementer(ISession)
class SSHSessionForCowrieUser:
    def __init__(self, avatar, reactor=None):
        """
        Construct an C{SSHSessionForCowrieUser}.

        @param avatar: The L{CowrieUser} for whom this is an SSH session.
        @param reactor: An L{IReactorProcess} used to handle shell and exec
            requests. Uses the default reactor if None.
        """
        self.protocol = None
        self.avatar = avatar
        self.server = avatar.server
        self.username = avatar.username
        self.environ = {}

    def openShell(self, processprotocol):
        self.protocol = insults.LoggingServerProtocol(
            protocol.HoneyPotInteractiveProtocol, self
        )
        self.protocol.makeConnection(processprotocol)
        processprotocol.makeConnection(session.wrapProtocol(self.protocol))

    def getPty(self, terminal, windowSize, attrs):
        # The terminal type is attacker input from the pty request and need
        # not be valid UTF-8.
        self.environ["TERM"] = terminal.decode("utf-8", errors="replace")
        self.avatar.conn.transport.events.dispatch(
            "cowrie.client.size",
            "Terminal Size: %(width)s %(height)s",
            width=windowSize[1],
            height=windowSize[0],
        )
        self.windowSize = windowSize

    def execCommand(self, processprotocol, cmd):
        self.protocol = insults.LoggingServerProtocol(
            protocol.HoneyPotExecProtocol, self, cmd
        )
        # LoggingServerProtocol detects exec sessions by identity against
        # cowrie.shell.protocol.HoneyPotExecProtocol, so the LLM exec protocol
        # was tagged interactive ("i"): the command never reached the ttylog,
        # every log hashed to sha256("") and all but the first were discarded
        # as duplicates. Tag it as exec explicitly, like the shell backend.
        self.protocol.type = "e"
        self.protocol.makeConnection(processprotocol)
        processprotocol.makeConnection(session.wrapProtocol(self.protocol))

    def closed(self) -> None:
        """
        this is reliably called on both logout and disconnect
        we notify the protocol here we lost the connection
        """
        if self.protocol:
            self.protocol.connectionLost("disconnected")
            self.protocol = None

    def eofReceived(self) -> None:
        if self.protocol:
            self.protocol.eofReceived()

    def windowChanged(self, windowSize):
        self.windowSize = windowSize
