//--------------------------------------------------------------------------
// Design Name: Booth Multiplication Algorithm 
// File Name: booth_parts.sv
// Description: Implementation of the Booth Multiplication Algorithm
// Version History
// * June 9, 2025 (sebastian ardelean): Finished the implementation 
// -------------------------------------------------------------------------
`timescale 1ns/1ps

module booth (
	input logic clk,
    input logic enable,
    input logic rst_n,
    input logic signed [7:0] A_in, // Operandul 1
    input logic signed [7:0] B_in, // Operandul 2
    output logic done,
    output logic signed [15:0] product
	      
	      );
   //control signals
   logic [7:0] c;
   logic       stop;
   
   tri [7:0]  output_buffer;
   
   // Register Outputs
   logic signed [7:0] A_reg, M_reg, Q_reg;
   logic	      Qm;
   logic signed [7:0] M_input;
   logic signed [7:0] Q_input;
   // Count
   logic [2:0] counter_o;
   logic       count_and_o;

   // Other intermediate signals
   logic signed [7:0] adder_o;
   logic [7:0]	      xor_o;

   logic signed [7:0] A_outbus;
   logic signed [7:0] Q_outbus;
   
   
   cu_booth ctrl_unit (
		 .clk(clk),
		 .start(enable),
		 .rst_n(rst_n),
		 .count(count_and_o),
		 .q0(Q_reg[0]),
		 .qm(Qm),
		 .stop(stop),
		 .c(c)
		 );
   
   assign done = stop;
  
   counter_nbits #(.WIDTH(3)) counter (
			  .clk(clk),
			  .rst_n(rst_n),
			  .en(c[5]),
			  .count(counter_o)
			  );

   and3_gate and_counter (
		       .a(counter_o[0]),
		       .b(counter_o[1]),
		       .c(counter_o[2]),
		       .y(count_and_o)
		       );
   
      

   register #(.WIDTH(8)) reg_A (
				.clk(clk),
				.rst_n(rst_n),
				.load_en(c[2]),
				.shift_en(c[4]),
                                .sr(A_reg[7]),
                                .sl(1'b0),
                                .shift_dir(c[4]),
				.d(adder_o),
				.q(A_reg)
				);
   
   
   register #(.WIDTH(8)) q_Q (
			      .clk(clk),
			      .rst_n(rst_n),
			      .load_en(c[1]),
			      .shift_en(c[4]),
			      .sr(A_reg[0]),
                              .sl(1'b0),
                              .shift_dir(c[4]),
			      .d(Q_input),
			      .q(Q_reg)
			      );
   
   register #(.WIDTH(1)) reg_Qm (
				 .clk(clk),
				 .rst_n(rst_n),
				 .load_en(c[1]),
				 .shift_en(c[4]),
				 .sr(Q_reg[0]),
                                 .sl(1'b0),
                                 .shift_dir(c[4]),
				 .d(1'b0),
				 .q(Qm)
				 );
	      

   register #(.WIDTH(8)) reg_M (
				.clk(clk),
				.rst_n(rst_n),
				.load_en(c[0]),
				.shift_en(1'b0),
				.sr(1'b0),
                                .sl(1'b0),
                                .shift_dir(1'b0),
				.d(M_input),
				.q(M_reg)
				);
   xorn_gate #(8) xor_instance (
			   .a(M_reg),
			   .b(c[3]),
			   .y(xor_o)
			   );

   adder #(8) adder_instance (
			      .cin(c[3]),
			      .a(A_reg),
			      .b(xor_o),
			      .sum(adder_o)
			      );

  assign M_input = A_in;
    assign Q_input = B_in;
    // Păstrezi bufferele pentru A_outbus și Q_outbus, sau pur și simplu
    // asignezi outbus = A_reg; (deoarece rezultatul final se află de obicei în A și Q). 
    // Pentru un ALU de 8 biți care înmulțește 2 numere de 8 biți, rezultatul ar avea 16 biți. 
    // Dacă ALU scoate doar 8 biți, de obicei se iau cei mai puțin semnificativi 8 biți (Q_reg).
    assign product = {A_reg,Q_reg};
   
   

  
endmodule // booth
