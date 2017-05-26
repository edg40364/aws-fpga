// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.


module test_hello_world();

import tb_type_defines_pkg::*;
`include "cl_common_defines.vh" // CL Defines with register addresses

// AXI ID
parameter [5:0] AXI_ID = 6'h0;

logic [31:0] rdata;
logic [15:0] vdip_value;
logic [15:0] vled_value;


   initial begin

      tb.power_up();
      
      tb.set_virtual_dip_switch(.dip(0));

      vdip_value = tb.get_virtual_dip_switch();

      $display ("value of vdip:%0x", vdip_value);

      $display ("Writing 0xABAD_CAFE to address 0x0");
      tb.poke(.addr(0), .data(32'habadcafe), .id(AXI_ID), .size(DataSize::UINT16), .intf(AxiPort::PORT_OCL)); // write register

      $display ("Writing 0x0123_4567 to address 0x1");
      tb.poke(.addr(1), .data(32'h0123456), .id(AXI_ID), .size(DataSize::UINT16), .intf(AxiPort::PORT_OCL)); // write register


      tb.peek(.addr(0), .data(rdata), .id(AXI_ID), .size(DataSize::UINT16), .intf(AxiPort::PORT_OCL));         // start read & write
      $display ("Reading 0x%x from address 0x0", rdata);

      if (rdata == 32'hDEAD_BEEF)
        $display ("Test PASSED");
      else
        $display ("Test FAILED");

      tb.peek_ocl(.addr(`VLED_REG_ADDR), .data(rdata));         // start read
      $display ("Reading 0x%x from address 0x%x", rdata, `VLED_REG_ADDR);

      if (rdata == 32'h0000_BEEF) // Check for LED register read
        $display ("Test PASSED");
      else
        $display ("Test FAILED");

      vled_value = tb.get_virtual_led();

      $display ("value of vled:%0x", vled_value);

      tb.kernel_reset();

      tb.power_down();
      
      $finish;
   end

endmodule // test_hello_world
