// Copyright (C) 2022 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the EXAMPLES_LICENSE file.

import cellular
import gpio
import uart
import ublox_cellular.sara_r4 show SaraR4

main:
  print "test"

  pwr_on := gpio.Pin 18
  reset_n := gpio.Pin 4
  tx := gpio.Pin 16
  rx := gpio.Pin 17
  rts := null
  cts := null

  port := uart.Port
    --tx=tx
    --rx=rx
    --rts=rts
    --cts=cts
    --baud_rate=cellular.Cellular.DEFAULT_BAUD_RATE

  modem := SaraR4 port --pwr_on=pwr_on --reset_n=reset_n
