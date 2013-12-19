# @file basic-call.rb
#
# Project Clearwater - IMS in the Cloud
# Copyright (C) 2013  Metaswitch Networks Ltd
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version, along with the "Special Exception" for use of
# the program along with SSL, set forth below. This program is distributed
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details. You should have received a copy of the GNU General Public
# License along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#
# The author can be reached by email at clearwater@metaswitch.com or by
# post at Metaswitch Networks Ltd, 100 Church St, Enfield EN2 6BQ, UK
#
# Special Exception
# Metaswitch Networks Ltd  grants you permission to copy, modify,
# propagate, and distribute a work formed by combining OpenSSL with The
# Software, or a work derivative of such a combination, even if such
# copying, modification, propagation, or distribution would otherwise
# violate the terms of the GPL. You must comply with the GPL in all
# respects for all of the code used other than OpenSSL.
# "OpenSSL" means OpenSSL toolkit software distributed by the OpenSSL
# Project and licensed under the OpenSSL Licenses, or a work based on such
# software and licensed under the OpenSSL Licenses.
# "OpenSSL Licenses" means the OpenSSL License and Original SSLeay License
# under which the OpenSSL Project distributes the OpenSSL toolkit software,
# as those licenses appear in the file LICENSE-OPENSSL.

TestDefinition.new("Basic Call - Mainline") do |t|
  caller = t.add_quaff_endpoint.quaff
  callee = t.add_quaff_endpoint.quaff
  caller.register
  callee.register

  t.add_quaff_scenario do
    call = caller.outgoing_call(callee.uri)

    call.send_request("INVITE", "hello world\r\n", {"Content-Type" => "text/plain"})
    call.recv_response("100")
    call.recv_response("180")
    data =  call.recv_response("200")

    call.create_dialog(data["message"])
    call.send_request("ACK")
    call.send_request("BYE")
    call.recv_response("200")
    call.end_call
    caller.unregister
  end

  t.add_quaff_scenario do
    call2 = callee.incoming_call
    call2.recv_request("INVITE")
    call2.send_response("100", "Trying")
    call2.send_response("180", "Ringing")
    call2.send_response("200", "OK", "hello world\r\n", nil, {"Content-Type" => "text/plain"})
    call2.recv_request("ACK")
    call2.recv_request("BYE")
    call2.send_response("200", "OK")
    call2.end_call
    callee.unregister
  end
end

TestDefinition.new("Basic Call - Unknown number") do |t|
  caller = t.add_quaff_endpoint
  callee = t.add_quaff_endpoint
  caller.register

  t.add_quaff_scenario do
    call = caller.outgoing_call(callee.uri)

    call.send_request("INVITE", "hello world\r\n", {"Content-Type" => "text/plain"})
    call.recv_response("100")
    call.recv_response("404")
    call.send_request("ACK")
    call.end_call
    caller.unregister
  end

end

TestDefinition.new("Basic Call - Rejected by remote endpoint") do |t|
  caller = t.add_quaff_endpoint
  callee = t.add_quaff_endpoint
  caller.register
  callee.register

  t.add_quaff_scenario do
    call = caller.outgoing_call(callee.uri)

    call.send_request("INVITE", "hello world\r\n", {"Content-Type" => "text/plain"})
    call.recv_response("100")
    call.recv_response("486")
    call.send_request("ACK")
    call.end_call
    caller.unregister
  end

  t.add_quaff_scenario do
    call2 = callee.incoming_call
    call2.recv_request("INVITE")
    call2.send_response("100", "Trying")
    call2.send_response("486", "")
    call2.recv_request("ACK")
    call2.end_call
    callee.unregister
  end
end

TestDefinition.new("Basic Call - Messages - Pager model") do |t|
  caller = t.add_quaff_endpoint
  callee = t.add_quaff_endpoint
  caller.register
  callee.register

  t.add_quaff_scenario do
    call = caller.outgoing_call(callee.uri)

    call.send_request("MESSAGE", "hello world\r\n", {"Content-Type" => "text/plain"})
    call.recv_response("200")
    call.end_call
    caller.unregister
  end

  t.add_quaff_scenario do
    call2 = callee.incoming_call
    call2.recv_request("MESSAGE")
    call2.send_response("200", "OK")
    call2.end_call
    callee.unregister
  end
end

TestDefinition.new("Basic Call - Pracks") do |t|
  caller = t.add_quaff_endpoint.quaff
  callee = t.add_quaff_endpoint.quaff
  caller.register
  callee.register

  t.add_quaff_scenario do
    call = caller.outgoing_call(callee.uri)

    call.send_request("INVITE", "hello world\r\n", {"Content-Type" => "text/plain"})
    call.recv_response("100")
    call.recv_response("180")

    call.update_branch
    call.send_request("PRACK")
    call.recv_response("200")

    data =  call.recv_response("200")
    call.create_dialog(data["message"])
    call.send_request("ACK")
    call.send_request("BYE")
    call.recv_response("200")
    call.end_call
    caller.unregister
  end

  t.add_quaff_scenario do
    call2 = callee.incoming_call
    data = call2.recv_request("INVITE")
    call2.send_response("100", "Trying")
    call2.send_response("180", "Ringing")

    call2.recv_request("PRACK")
    call2.send_response("200", "OK")

    call2.assoc_with_msg(data["message"])
    call2.send_response("200", "OK", "hello world\r\n", nil, {"Content-Type" => "text/plain"})
    call2.recv_request("ACK")
    call2.recv_request("BYE")
    call2.send_response("200", "OK")
    call2.end_call
    callee.unregister
  end
end
