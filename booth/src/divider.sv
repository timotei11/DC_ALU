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

    // Semnale combinationale declarate in afara blocului secvential
    logic [7:0] next_A;
    logic [7:0] next_Q;
    logic [8:0] sub_res;

    // Calculam shiftarile si scaderea concurent
    // Extindem la 9 biti cu 1'b0 pentru a prinde bitul de "borrow" (imprumut) la scadere
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
        end else if (start && divisor == 0) begin
            A <= 8'b0;
            Q <= 8'hFF;
            active <= 1'b0;
            done <= 1'b1;
        end else if (start && !active) begin
            // Initializare impartire
            A <= 8'b0;
            Q <= dividend;
            M <= divisor;
            count <= 4'd8;
            active <= 1'b1;
            done <= 1'b0;
        end else if (active) begin
            if (count > 0) begin
                if (sub_res[8] == 1'b0) begin // Daca next_A >= M (niciun imprumut la scadere)
                    A <= sub_res[7:0];        // Salvam rezultatul scaderii
                    Q <= {next_Q[7:1], 1'b1}; // Setam LSB din Q la 1
                end else begin                // Daca next_A < M
                    A <= next_A;              // Refacere (restoring) la valoarea shiftata
                    Q <= next_Q;              // LSB ramane 0
                end
                count <= count - 1;
            end else begin
                active <= 1'b0;
                done <= 1'b1;
            end
        end else if (start) begin
            done <= 1'b0; // reseteaza doar cand pornesti o operatie noua
        end
    end

    // Conectarea rezultatelor la iesirile modulului
    assign quotient = Q;
    assign remainder = A;

endmodule