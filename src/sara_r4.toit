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
Driver for Sara-R4, GSM communicating over NB-IoT & M1.
*/
class SaraR4 extends UBloxCellular:
  static CONFIG_ ::= {
    // Disables the TCP socket Graceful Dormant Close feature. With this enabled,
    // the module waits for ack (or timeout) from peer, before closing socket
    // resources.
    "+USOCLCFG": [0],
  }

  pwr_on/gpio.Pin?
  reset_n/gpio.Pin?

  constructor uart/uart.Port --logger=log.default --.pwr_on=null --.reset_n=null --is_always_online/bool:
    super
      uart
      --logger=logger
      --config=CONFIG_
      --cat_m1
      --cat_nb1
      --preferred_baud_rate=460_800
      --async_socket_connect
      --async_socket_close
      --use_psm=not is_always_online

  on_connected_ session/at.Session:
    // Do nothing.

  psm_enabled_psv_target -> List:
    return [4]

  reboot_after_cedrxs_or_cpsms_changes -> bool:
    return false

  on_reset session/at.Session:
    session.send CFUN.reset

  power_on -> none:
    if pwr_on:
      pwr_on.set 1
      sleep --ms=150
      pwr_on.set 0
      // The chip needs the pin to be off for 250ms so it doesn't turn off again.
      sleep --ms=250

  power_off -> none:
    if pwr_on:
      pwr_on.set 1
      sleep --ms=1500
      pwr_on.set 0

  reset -> none:
    if reset_n:
      reset_n.set 1
      sleep --ms=10_000
      reset_n.set 0

  recover_modem:
    reset
