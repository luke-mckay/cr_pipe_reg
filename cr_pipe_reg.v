// SPDX-License-Identifier: Apache-2.0
/*
 * Copyright 2021, Luke E. McKay.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* 
 * Pipeline Registers
 * Version 0.1.0
 * A set of pipeline registers specified by the input parameters
 * pWidth and pStages. pWidth determines the size/width of the signal passed to
 * each stage of registers. pStages is the length/number of pipeline registers
 * generated. This accepts values of 0 (yes, it just passes data from input to
 * output...) up to however many stages specified. 0 / passthrough is available
 * so the core can be inserted in places where the pipeline stages may be needed
 * during timing closure.
 * At reset the each stage of the pipeline is filled with the StaticResetData
 * value.  This value should be a constant value that you need the output to be
 * at the release of reset.  
 */
module cr_pipe_reg
#(
  parameter pWidth  = 10,
  parameter pStages = 5,
  parameter pRstMode = 0 //!< 0 -> asynchronous;  1 -> synchronous; >1 -> none
)(
  //# {{clocks|}}
  input                    Clk,              //!< Clock
  input                    Rst_n,            //!< Reset
  //# {{data|}}
  input      [pWidth-1:0]  StaticResetData,  //!< Default value of data at reset
  input      [pWidth-1:0]  D,                //!< Data In
  output reg [pWidth-1:0]  Q                 //!< Data Out
);

  generate
    genvar i;
    if (pStages == 0) // --------------------  Passthrough  --------------
    begin
      always @(*)
        Q = D;
    end
    else if (pRstMode == 0) // --------------  Async Reset  --------------
    begin
      if (pStages == 1) // ------------------  Single stage
      begin
        always @(posedge Clk or negedge Rst_n)
        begin
          if (!Rst_n)
          begin
            Q <= StaticResetData;
          end
          else
          begin
            Q <= D;
          end
        end
      end
      else // -------------------------------  Multi-stage
      begin
        reg [pWidth*(pStages-1)-1:0] tmp_q;
        always @(posedge Clk or negedge Rst_n)
        begin
          if (!Rst_n)
          begin
            tmp_q[pWidth-1:0] <= StaticResetData;
            Q                 <= StaticResetData;
          end
          else
          begin
            tmp_q[pWidth-1:0] <= D;
            Q                 <= tmp_q[pWidth*(pStages-1)-1:pWidth*(pStages-2)];
          end
        end
        for (i = 1; i < pStages-1; i = i + 1)
        begin : pipeline
          always @ (posedge Clk or negedge Rst_n)
            tmp_q[pWidth*(i+1)-1:pWidth*i] <= (!Rst_n) ? StaticResetData : tmp_q[pWidth*i-1:pWidth*(i-1)];
        end
      end
    end
    else if (pRstMode == 1) // --------------  Sync Reset  --------------
    begin
      if (pStages == 1)  // -----------------  Single stage
      begin
        always @(posedge Clk)
        begin
          if (!Rst_n)
          begin
            Q <= StaticResetData;
          end
          else
          begin
            Q <= D;
          end
        end
      end
      else // -------------------------------  Multi-stage
      begin
        reg [pWidth*(pStages-1)-1:0] tmp_q;
        always @(posedge Clk)
        begin
          if (!Rst_n)
          begin
            tmp_q[pWidth-1:0] <= StaticResetData;
            Q                 <= StaticResetData;
          end
          else
          begin
            tmp_q[pWidth-1:0] <= D;
            Q                 <= tmp_q[pWidth*(pStages-1)-1:pWidth*(pStages-2)];
          end
        end
        for (i = 1; i < pStages-1; i = i + 1)
        begin : pipeline
          always @ (posedge Clk)
            tmp_q[pWidth*(i+1)-1:pWidth*i] <= (!Rst_n) ? StaticResetData : tmp_q[pWidth*i-1:pWidth*(i-1)];
        end
      end
    end
    else // ---------------------------------  No Reset  --------------
    begin
      if (pStages == 1) // ------------------  Single stage
      begin
        always @(posedge Clk)
        begin
          Q <= D;
        end
      end
      else // -------------------------------  Multi-stage
      begin
        reg [pWidth*(pStages-1)-1:0] tmp_q;
        always @(posedge Clk)
        begin
          tmp_q[pWidth-1:0] <= D;
          Q                 <= tmp_q[pWidth*(pStages-1)-1:pWidth*(pStages-2)];
        end
        for (i = 1; i < pStages-1; i = i + 1)
        begin : pipeline
          always @ (posedge Clk)
            tmp_q[pWidth*(i+1)-1:pWidth*i] <= tmp_q[pWidth*i-1:pWidth*(i-1)];
        end
      end
    end
  endgenerate

endmodule
