// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
This example demonstrates how to connect to a network service through the
  cellular network provided by a Sara R4 modem.

The example resets the modem before connecting to remove any unexpected state
  before connecting. However, this makes the connection time fairly long.
*/
import monitor
import http
import net.cellular

import ublox.sara_r4 show SaraR4Service

main:
  spawn::
    service := SaraR4Service
    service.install

  config ::= {
    cellular.CONFIG_APN: "onomondo",
    cellular.CONFIG_BANDS: [20, 8],

    cellular.CONFIG_UART_TX: 16,
    cellular.CONFIG_UART_RX: 17,

    cellular.CONFIG_POWER: [18, cellular.CONFIG_OPEN_DRAIN],
    cellular.CONFIG_RESET: [ 4, cellular.CONFIG_OPEN_DRAIN],
  }

  print "Opening cellular network"
  network := cellular.open config

  try:
    client := http.Client network
    host := "www.google.com"
    response := client.get host "/"

    bytes := 0
    while data := response.body.read:
      bytes += data.size

    print "Read $bytes bytes from http://$host/ via cellular"

  finally:
    network.close
