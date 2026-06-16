`timescale 1ns/1ps

module alu (
    input logic clk,
    input logic rst_n,
    input logic signed [7:0] A,
    input logic signed [7:0] B,
    input logic [3:0] alu_ctrl,
    input logic start,

    output logic signed [7:0] result,
    output logic Z,
    output logic N,
    output logic V,
    output logic ready
);

    localparam ADD = 4'd0;
    localparam SUB = 4'd1;
    localparam MUL = 4'd2;
    localparam DIV = 4'd3;
    localparam AND = 4'd4;
    localparam OR  = 4'd5;
    localparam XOR = 4'd6;
    localparam LSL = 4'd7;
    localparam LSR = 4'd8;


    // Adder / Subtractor

    logic cin;
    logic [7:0] b_in;
    logic signed [7:0] add_sub_res;

    assign cin  = (alu_ctrl == SUB) ? 1'b1 : 1'b0;
    assign b_in = (alu_ctrl == SUB) ? ~B   : B;

    adder #(8) add_sub_inst (
        .cin(cin),
        .a(A),
        .b(b_in),
        .sum(add_sub_res)
    );


    // Booth Multiplier

    logic signed [15:0] mul_product;
    logic mul_overflow;
    logic mul_done;

    booth booth_inst (
        .clk(clk),
        .enable(start && (alu_ctrl == MUL)),
        .rst_n(rst_n),
        .A_in(A),
        .B_in(B),
        .done(mul_done),
        .product(mul_product)
    );

    assign mul_overflow = mul_done &&
                          (mul_product[15:8] != {8{mul_product[7]}});

    // Signed Divider (nou)

    logic signed [7:0] div_res;
    logic signed [7:0] remainder;
    logic div_done;

    // Extragem magnitudinile pentru divider ul unsigned
    logic [7:0] div_dividend, div_divisor;
    logic [7:0] div_quotient_raw, div_remainder_raw;
    logic div_negate_result; // 1 daca catul trebuie negat

    assign div_dividend     = A[7] ? (~A + 1'b1) : A;  // |A|
    assign div_divisor      = B[7] ? (~B + 1'b1) : B;  // |B|
    assign div_negate_result = A[7] ^ B[7];              // semne diferite -> catul e negativ

    divider div_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start && (alu_ctrl == DIV)),
        .dividend(div_dividend),
        .divisor(div_divisor),
        .quotient(div_quotient_raw),
        .remainder(div_remainder_raw),
        .done(div_done)
    );

    // Aplicam semnul la catul final
    assign div_res   = div_done ? (div_negate_result ?
                                   (~div_quotient_raw + 1'b1) :
                                   div_quotient_raw) : 8'b0;
    assign remainder = div_done ? (A[7] ?
                                   (~div_remainder_raw + 1'b1) :
                                   div_remainder_raw) : 8'b0;


    // Multiplexor principal

    always_comb begin
        result = 8'b0;
        ready  = 1'b0;

        case (alu_ctrl)
            ADD: begin result = add_sub_res;       ready = 1'b1;     end
            SUB: begin result = add_sub_res;       ready = 1'b1;     end
            MUL: begin result = mul_product[7:0];  ready = mul_done; end
            DIV: begin result = div_res;           ready = div_done; end
            AND: begin result = A & B;             ready = 1'b1;     end
            OR:  begin result = A | B;             ready = 1'b1;     end
            XOR: begin result = A ^ B;             ready = 1'b1;     end
            LSL: begin result = A << B[2:0];       ready = 1'b1;     end
            LSR: begin result = $signed(A) >>> B[2:0]; ready = 1'b1; end
            default: begin result = 8'b0; ready = 1'b0; end
        endcase
    end


    // Flaguri - active doar cand ready = 1

    logic overflow_arith;

    assign overflow_arith =
        ((alu_ctrl == ADD) && ~(A[7] ^ B[7])     && (A[7] ^ result[7])) |
        ((alu_ctrl == SUB) &&  (A[7] ^ B[7])     && (A[7] ^ result[7]));

    assign Z = ready && (result == 8'b0);
    assign N = ready && result[7];
    assign V = ready && (overflow_arith | ((alu_ctrl == MUL) && mul_overflow));

endmodule