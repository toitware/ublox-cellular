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

  list_equals a/List b/List -> bool:
    if a.size != b.size: return false
    a.size.repeat:
      if a[it] != b[it]: return false
    return true

  on_connected_ session/at.Session:
    // Attach to network.
    changed := false
    upsd_map_cid_target := [0, 100, 1]
    upsd_map_cid := session.send (UPSD.read --parameters=[0, 100])
    if not list_equals upsd_map_cid.last upsd_map_cid_target:
      session.set "+UPSD" upsd_map_cid_target
      changed = true

    upsd_protocol_target := [0, 0, 0]
    upsd_protocol := session.send (UPSD.read --parameters=[0, 0])
    if not list_equals upsd_protocol.last upsd_protocol_target:
      session.set "+UPSD" upsd_protocol_target
      changed = true

    if changed:
      send_abortable_ session (UPSDA --action=0)
      send_abortable_ session (UPSDA --action=3)

  psm_enabled_psv_target -> List:
    return [1, 2000]  // TODO(kasper): Testing - go to sleep after ~9.2s.

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

class UPSDA extends at.Command:
  // UPSDA times out after 180s, but since it can be aborted, any timeout can be used.
  static MAX_TIMEOUT ::= Duration --m=3

  constructor --action/int:
    super.set "+UPSDA" --parameters=[0, action] --timeout=compute_timeout

  // We use the deadline in the task to let the AT processor know that we can abort
  // the UPSDA operation by sending more AT commands.
  static compute_timeout -> Duration:
    return min MAX_TIMEOUT (Duration --us=(task.deadline - Time.monotonic_us))

class UPSD extends at.Command:
  // TODO(kasper): This is a bit of hack that extends the at.Command
  // with support for read parameters.
  parameters/List ::= ?
  constructor.read --.parameters=[]:
    super.read "+UPSD"
