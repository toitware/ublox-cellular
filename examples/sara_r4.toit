// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

/**
This example demonstrates how to create a Sara R4 driver and connect it to a
  cellular network.

The example resets the modem before connecting to remove any unexpected state
  before connecting. However, this makes the connection time fairly long.
*/
import cellular
import gpio
import http.client show Client
import log
import monitor
import net
import uart
import ublox_cellular.sara_r4 show SaraR4

APN ::= "onomondo"
BANDS ::= [ 20, 8 ]
RATS ::= null

TX_PIN_NUM ::= 16
RX_PIN_NUM ::= 17
PWR_ON_NUM ::= 18
RESET_N_NUM ::= 4

main:
  driver := create_driver

  if not connect driver: return

  network_interface := driver.network_interface
  visit_google network_interface
  driver.close

create_driver -> SaraR4:
  pwr_on :=  gpio.Pin PWR_ON_NUM
  pwr_on.config --output --open_drain
  pwr_on.set 1
  reset_n := gpio.Pin RESET_N_NUM
  reset_n.config --output --open_drain
  reset_n.set 1
  tx := gpio.Pin TX_PIN_NUM
  rx := gpio.Pin RX_PIN_NUM

  port := uart.Port --tx=tx --rx=rx --baud_rate=cellular.Cellular.DEFAULT_BAUD_RATE

  return SaraR4 port --pwr_on=(gpio.InvertedPin pwr_on) --reset_n=(gpio.InvertedPin reset_n) --logger=log.default

reset driver:
  driver.wait_for_ready
  driver.reset

connect driver/cellular.Cellular -> bool:
  print "WAITING FOR MODULE..."
  driver.wait_for_ready
  print "model: $driver.model"
  print "version $driver.version"
  print "iccid: $driver.iccid"
  print "CONFIGURING..."
  driver.configure APN --bands=BANDS --rats=RATS
  print "ENABLING RADIO..."
  driver.enable_radio
  print "CONNECTING..."
  try:
    dur := Duration.of:
      driver.connect
    print "CONNECTED (in $dur)"
  finally: | is_exception _ |
    if is_exception:
      critical_do:
        driver.close
        print "CONNECTION FAILED"
        return false
  return true

visit_google network_interface/net.Interface:
  host := "www.google.com"

  network := network_interface
  client := Client network

  response := client.get host "/"

  bytes := 0
  while data := response.body.read:
    bytes += data.size

  print "Read $bytes bytes from http://$host/"
