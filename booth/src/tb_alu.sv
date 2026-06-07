`timescale 1ns/1ps

module tb_alu();

    // Semnale pentru conectarea la ALU
    logic clk;
    logic rst_n;
    logic [7:0] A;
    logic [7:0] B;
    logic [3:0] alu_ctrl;
    logic start;
    
    logic [7:0] result;
    logic Z, N, V, ready;

    // Instanțierea modulului Principal (Device Under Test)
    alu dut (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .alu_ctrl(alu_ctrl),
        .start(start),
        .result(result),
        .Z(Z),
        .N(N),
        .V(V),
        .ready(ready)
    );

    // Generarea semnalului de ceas (Perioada = 10ns)
    always #5 clk = ~clk;

    // Blocul principal de testare
    initial begin
        // Inițializare semnale
        clk = 0;
        rst_n = 0;
        A = 8'd0;
        B = 8'd0;
        alu_ctrl = 4'd0;
        start = 0;

        // Resetare sistem
        $display("--- Incepere Simulare ---");
        #15 rst_n = 1;

        // ------------------------------------------------
        // Test 1: Adunare (ADD = 4'd0)
        // ------------------------------------------------
        #10;
        A = 8'd15; B = 8'd10; alu_ctrl = 4'd0;
        #10;
        $display("ADD: %d + %d = %d (Z=%b, N=%b, V=%b)", A, B, result, Z, N, V);

        // ------------------------------------------------
        // Test 2: Scadere (SUB = 4'd1)
        // ------------------------------------------------
        #10;
        A = 8'd20; B = 8'd5; alu_ctrl = 4'd1;
        #10;
        $display("SUB: %d - %d = %d (Z=%b, N=%b, V=%b)", A, B, result, Z, N, V);

        // ------------------------------------------------
        // Test 3: Inmultire (MUL = 4'd2) - Operatie secventiala
        // ------------------------------------------------
        #10;
        A = 8'd6; B = 8'd7; alu_ctrl = 4'd2;
        start = 1; // Dam impulsul de start
        #10 start = 0; // Il oprim pentru a lasa masina de stari sa lucreze
        
        // Asteptam pana cand semnalul 'ready' devine 1
        wait(ready == 1'b1); 
        #5; // O mica pauza sa se stabilizeze rezultatul
        $display("MUL: %d * %d = %d (Gata!)", A, B, result);

        // ------------------------------------------------
        // Test 4: Impartire (DIV = 4'd3) - Operatie secventiala
        // ------------------------------------------------
        #20; // Pauza intre operatii
        A = 8'd45; B = 8'd5; alu_ctrl = 4'd3;
        start = 1;
        #10 start = 0;
        
        wait(ready == 1'b1);
        #5;
        $display("DIV: %d / %d = Cât: %d", A, B, result);

        // ------------------------------------------------
        // Test 5: Logic AND (AND = 4'd4)
        // ------------------------------------------------
        #20;
        A = 8'b1100_1100; B = 8'b1010_1010; alu_ctrl = 4'd4;
        #10;
        $display("AND: %b & %b = %b", A, B, result);

        // Incheiere simulare
        #50;
        $display("--- Simulare Terminata ---");
        $stop; // Opreste simularea in ModelSim fara a inchide programul
    end

endmodule