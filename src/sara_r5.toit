// Copyright (C) 2022 Toitware ApS. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import at
import bytes
import gpio
import log
import uart

import .ublox_cellular
import cellular.base show *

/**
Driver for Sara-R5, GSM communicating over NB-IoT & M1.
*/
class SaraR5 extends UBloxCellular:
  static CONFIG_ ::= {:}

  pwr_on/gpio.Pin?
  reset_n/gpio.Pin?

  constructor uart/uart.Port --logger=log.default --.pwr_on=null --.reset_n=null --is_always_online/bool:
    super
      uart
      --logger=logger
      --config=CONFIG_
      --cat_m1
      --preferred_baud_rate=3_250_000
      --use_psm=not is_always_online

  on_connected_ session/at.Session:
    // Attach to network.
    session.set "+UPSD" [0, 100, 1]
    session.set "+UPSD" [0, 0, 0]
    session.set "+UPSDA" [0, 0]
    session.set "+UPSDA" [0, 3]

  on_reset session/at.Session:
    session.send
      CFUN.reset --reset_sim

  power_on -> none:
    if pwr_on:
      pwr_on.set 1
      sleep --ms=1000
      pwr_on.set 0

  power_off -> none:
    if pwr_on and reset_n:
      pwr_on.set 1
      reset_n.set 1
      sleep --ms=23_000
      pwr_on.set 0
      sleep --ms=1500
      reset_n.set 0

  reset -> none:
    if reset_n:
      reset_n.set 1
      sleep --ms=100
      reset_n.set 0

  // Prefer reset over power_off (100ms vs ~25s).
  recover_modem:
    reset
