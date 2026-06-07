`timescale 1ns/1ps

module divider (
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic [7:0] dividend,
    input logic [7:0] divisor,
    output logic [7:0] quotient,
    output logic [7:0] remainder,
    output logic done
);

    logic [7:0] A, Q, M;
    logic [3:0] count;
    logic active;

    // Semnale combinaționale declarate în afara blocului secvențial
    logic [7:0] next_A;
    logic [7:0] next_Q;
    logic [8:0] sub_res;

    // Calculăm shiftările și scăderea concurent
    // Extindem la 9 biți cu 1'b0 pentru a prinde bitul de "borrow" (împrumut) la scădere
    assign next_A = {A[6:0], Q[7]};
    assign next_Q = {Q[6:0], 1'b0};
    assign sub_res = {1'b0, next_A} - {1'b0, M}; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A <= 8'b0;
            Q <= 8'b0;
            M <= 8'b0;
            count <= 4'b0;
            active <= 1'b0;
            done <= 1'b0;
        end else if (start && !active) begin
            // Inițializare împărțire
            A <= 8'b0;
            Q <= dividend;
            M <= divisor;
            count <= 4'd8;
            active <= 1'b1;
            done <= 1'b0;
        end else if (active) begin
            if (count > 0) begin
                if (sub_res[8] == 1'b0) begin // Dacă next_A >= M (niciun împrumut la scădere)
                    A <= sub_res[7:0];        // Salvăm rezultatul scăderii
                    Q <= {next_Q[7:1], 1'b1}; // Setăm LSB din Q la 1
                end else begin                // Dacă next_A < M
                    A <= next_A;              // Refacere (restoring) la valoarea shiftată
                    Q <= next_Q;              // LSB rămâne 0
                end
                count <= count - 1;
            end else begin
                active <= 1'b0;
                done <= 1'b1;
            end
        end else begin
            done <= 1'b0; // Resetare flag done după un ciclu
        end
    end

    // Conectarea rezultatelor la ieșirile modulului
    assign quotient = Q;
    assign remainder = A;

endmodule