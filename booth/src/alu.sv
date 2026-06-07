`timescale 1ns/1ps

module alu (
    input logic clk,
    input logic rst_n,
    input logic [7:0] A,
    input logic [7:0] B,
    input logic [3:0] alu_ctrl, // Semnal de selecție operație
    input logic start,          // Semnal de start pentru operații secvențiale
    
    output logic [7:0] result,
    output logic Z, // Zero flag
    output logic N, // Negative flag
    output logic V, // Overflow flag
    output logic ready // Indică dacă rezultatul este valid
);

    // Coduri operații (OpCodes)
    localparam ADD = 4'd0;
    localparam SUB = 4'd1;
    localparam MUL = 4'd2;
    localparam DIV = 4'd3;
    localparam AND = 4'd4;
    localparam OR  = 4'd5;
    localparam XOR = 4'd6;
    localparam LSL = 4'd7;
    localparam LSR = 4'd8;

    // Semnale interne pentru Adder
    logic cin;
    logic [7:0] b_in;
    logic [7:0] add_sub_res;

    // Configurare sumator pentru Adunare sau Scădere (complement față de 2)
    assign cin = (alu_ctrl == SUB) ? 1'b1 : 1'b0;
    assign b_in = (alu_ctrl == SUB) ? ~B : B;

    adder #(8) add_sub_inst (
        .cin(cin),
        .a(A),
        .b(b_in),
        .sum(add_sub_res)
    );

    // Semnale și instanțiere pentru Multiplicator Booth
    logic [7:0] mul_res;
    logic mul_done;
    
    booth booth_inst (
        .clk(clk),
        .enable(start && (alu_ctrl == MUL)),
        .rst_n(rst_n),
        .A_in(A),   // Aici folosim modificarea menționată la pasul 1
        .B_in(B),
        .done(mul_done),
        .outbus(mul_res)
    );

    // Semnale și instanțiere pentru Divizor
    logic [7:0] div_res;
    logic [7:0] remainder;
    logic div_done;

    divider div_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start && (alu_ctrl == DIV)),
        .dividend(A),
        .divisor(B),
        .quotient(div_res),
        .remainder(remainder),
        .done(div_done)
    );

    // Multiplexor principal (Aici rutezi rezultatul final)
    always_comb begin
        result = 8'b0;
        ready = 1'b0;

        case (alu_ctrl)
            ADD: begin result = add_sub_res; ready = 1'b1; end
            SUB: begin result = add_sub_res; ready = 1'b1; end
            MUL: begin result = mul_res;     ready = mul_done; end
            DIV: begin result = div_res;     ready = div_done; end
            AND: begin result = A & B;       ready = 1'b1; end
            OR:  begin result = A | B;       ready = 1'b1; end
            XOR: begin result = A ^ B;       ready = 1'b1; end
            LSL: begin result = A << B[2:0]; ready = 1'b1; end // Shiftare folosind 3 biți din B
            LSR: begin result = A >> B[2:0]; ready = 1'b1; end
            default: result = 8'b0;
        endcase
    end

    // Calculare Flag-uri (Se actualizează doar când rezultatul este gata)
    assign Z = (result == 8'b0) ? 1'b1 : 1'b0;
    assign N = result[7];
    
    // Overflow apare la ADD dacă numerele au același semn, dar rezultatul are semn opus
    // La SUB, overflow apare dacă scazi un număr pozitiv dintr-unul negativ și rezultatul e pozitiv, etc.
    assign V = ((alu_ctrl == ADD) && ~(A[7] ^ B[7]) && (A[7] ^ result[7])) |
               ((alu_ctrl == SUB) &&  (A[7] ^ B[7]) && (A[7] ^ result[7]));

endmodule