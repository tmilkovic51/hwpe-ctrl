/* 
 * hwpe_ctrl_regfile_register.sv
 * Author: Francesco Conti <fconti@iis.ee.ethz.ch>
 * Edited: Luka Macan <luka.macan@fer.hr>
*/

module hwpe_ctrl_regfile_register
#(
    parameter ADDR_WIDTH    = 5,
    parameter DATA_WIDTH    = 32,
    parameter NUM_BYTE      = DATA_WIDTH/8
)
(
    input  logic                                clk,
    input  logic                                rst_n,
    input  logic                                clear,

    // Read port
    input  logic                                ReadEnable,
    input  logic [ADDR_WIDTH-1:0]               ReadAddr,
    output logic [DATA_WIDTH-1:0]               ReadData,

    // Write port
    input  logic                                WriteEnable,
    input  logic [ADDR_WIDTH-1:0]               WriteAddr,
    input  logic [NUM_BYTE-1:0][7:0]            WriteData,
    input  logic [NUM_BYTE-1:0]                 WriteBE,

    // Memory content (false paths!)
    output logic [2**ADDR_WIDTH-1:0][DATA_WIDTH-1:0] MemContent
);

localparam NUM_WORDS = 2**ADDR_WIDTH;

// Read address register, located at the input of the address decoder
logic [ADDR_WIDTH-1:0]              RAddrRegxDP;
logic [NUM_BYTE-1:0][7:0]           MemContentxDP[NUM_WORDS];

logic [NUM_WORDS-1:0][NUM_BYTE-1:0] WAddrOneHotxD;

int unsigned i, j, k, l;

//-----------------------------------------------------------------------------
//-- READ : Read address register
//-----------------------------------------------------------------------------
always_ff @(posedge clk)
begin : p_RAddrReg
    if(ReadEnable)
        RAddrRegxDP <= ReadAddr;
end


//-----------------------------------------------------------------------------
//-- READ : Read address decoder RAD
//-----------------------------------------------------------------------------  
assign ReadData = MemContentxDP[RAddrRegxDP];


//-----------------------------------------------------------------------------
//-- WRITE : Write Address Decoder (WAD), combinatorial process
//-----------------------------------------------------------------------------
always_comb
begin : p_WAD
    for(i=0; i<NUM_WORDS; i++)
    begin : p_WordIter
        for(j=0; j<NUM_BYTE; j++)
        begin : p_ByteIter
            if ( (WriteEnable == 1'b1 ) && (WriteBE[j] == 1'b1) &&  (WriteAddr == i) )
                WAddrOneHotxD[i][j] = 1'b1;
            else
                WAddrOneHotxD[i][j] = 1'b0;
        end
    end
end


//-----------------------------------------------------------------------------
//-- WRITE : Write operation
//-----------------------------------------------------------------------------  
always_ff @(posedge clk, negedge rst_n)
begin : register_wdata
    for(k=0; k<NUM_WORDS; k++)
    begin : w_WordIter
        for(l=0; l<NUM_BYTE; l++)
        begin : w_ByteIter
            if(~rst_n)
                MemContentxDP[k][l] = 8'b0;
            else if(clear)
                MemContentxDP[k][l] = 8'b0;
            else if(WAddrOneHotxD[k][l])
                MemContentxDP[k][l] = WriteData[l];
        end
    end
end

genvar p;
generate
for(p=0; p<NUM_WORDS; p++) begin : MemContentOut_Iter
    assign MemContent[p] = MemContentxDP[p];
end
endgenerate

endmodule // hwpe_ctrl_regfile_register
