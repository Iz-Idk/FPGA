LIBRARY 	ieee;
USE 		ieee.std_logic_1164.all;
USE 		ieee.std_logic_arith.all;
use 		IEEE.numeric_std.all;

--	Equipo 5
--	Practica 4.1
--	Andrés Sarellano
--	Luis Ángel Ramiro
--	Jesús Rodríguez
--	Izel Ávila


ENTITY vga_interface2 IS
	GENERIC(
		H_LOW_5:	natural	:= 96; --Hpulse
		HBP_5: 		natural 	:= 48; --HBP_5
		H_HIGH_5:	natural 	:= 640; --Hactive_5
		HFP_5: 		natural  := 16; --HFP_5
		V_LOW_5: 	natural  := 2; --Vpulse
		VBP_5: 		natural	:= 33; --VBP_5
		V_HIGH_5: 	natural  := 480; --Vactive_5
		VFP_5: 		natural	:= 10 --VFP_5
	); 
	PORT(
		clk_5: 					IN 	std_logic; --50MHz in our board
		x0_5, x1_5, y0_5, y1_5, Srst: IN	std_logic;
		H_sync_5, V_sync_5: 	OUT	std_logic;
		BLANKn_5, SYNCn_5 : 	OUT 	std_logic;
		R_5, G_5, B_5: 			OUT 	std_logic_vector(3 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE behavior OF vga_interface2 IS

	SIGNAL Hsync_5, Vsync_5, Hactive_5, Vactive_5, dena_5, clk_5_vga:	std_logic;
	SIGNAL clk_figura_5: STD_LOGIC;
	
	

	SIGNAL xaxis_5: natural := 300;
	SIGNAL yaxis_5: natural := 200;
	
	SIGNAL altura_5 : natural;
	SIGNAL ancho_5 : natural;
	
	SIGNAL contador_5 : POSITIVE;
	
BEGIN
-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------		

		altura_5 <= 27;
		ancho_5 <= 47;
		--Static signals for DACs:
		BLANKn_5 	<= '1'; --no direct blanking
		SYNCn_5 	<= '0'; --no sync on green
		
		--	Crear reloj
		PROCESS( clk_5 )
		BEGIN
			IF rising_edge( clk_5 ) THEN 
				clk_5_vga <= not clk_5_vga;
				contador_5 <= contador_5 + 1;
					-- ( 50MHz/1Hz ) * 0.1
					IF( contador_5 = 150000 ) THEN
						clk_figura_5   <= NOT clk_figura_5;
						contador_5 <= 1;
					END IF;
			END IF;
		END PROCESS;
	
		--Horizontal signals generation:
		PROCESS( clk_5_vga )
			VARIABLE Hcontador_5:	natural RANGE 0 to H_LOW_5 + HBP_5 + H_HIGH_5 + HFP_5;
		BEGIN
			IF rising_edge( clk_5_vga ) THEN 
				Hcontador_5 := Hcontador_5 + 1;
				IF Hcontador_5 = H_LOW_5 THEN 
					Hsync_5 	<= '1';
				ELSIF Hcontador_5 = H_LOW_5 + HBP_5 THEN 
					Hactive_5 	<= '1';
				ELSIF Hcontador_5 = H_LOW_5 + HBP_5 + H_HIGH_5 THEN 
					Hactive_5 	<= '0';
				ELSIF Hcontador_5 = H_LOW_5 + HBP_5 + H_HIGH_5 + HFP_5 THEN 
					Hsync_5 	<= '0'; 
					Hcontador_5 	:=  0;
				END IF;
			END IF;
		END PROCESS;
		
		--Vertical signals generation:
		PROCESS( Hsync_5 )
			VARIABLE Vcontador_5:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		BEGIN
			IF rising_edge( Hsync_5 ) THEN 
				Vcontador_5 := Vcontador_5 + 1;
				IF Vcontador_5 = V_LOW_5 THEN 
					Vsync_5 	<= '1';
				ELSIF Vcontador_5 = V_LOW_5 + VBP_5 THEN 
					Vactive_5 	<= '1';
				ELSIF Vcontador_5 = V_LOW_5 + VBP_5 + V_HIGH_5 THEN 
					Vactive_5 	<= '0';
				ELSIF Vcontador_5 = V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5 THEN 
					Vsync_5 	<= '0'; 
					Vcontador_5 	:=  0;
				END IF;
			END IF;
		END PROCESS;
	
		H_sync_5 <= Hsync_5;
		V_sync_5 <= Vsync_5;
	
		---Display enable generation:
		dena_5 <= Hactive_5 and Vactive_5;
	
-------------------------------------------------------
--Part 2: IMAGE GENERATOR
-------------------------------------------------------	
	PROCESS( Hsync_5, Vactive_5, Hactive_5, clk_5_vga, clk_5, dena_5, x0_5, x1_5, y0_5, y1_5, Srst )
		VARIABLE line_count_V:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		VARIABLE line_count_H: natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
----		--	Limite inferior Vertical
----		VARIABLE limInfV: integer := 180;
----		VARIABLE limSupV: integer := 300;
----		--	Limite inferior Horizontal
----		VARIABLE limInfH: integer :=240;
----		VARIABLE limSupH: integer :=360;
	BEGIN
		IF rising_edge( Hsync_5 ) THEN
			IF Vactive_5 = '1' THEN
				line_count_V := line_count_V + 1;
			ELSE
				line_count_V := 0;
			END IF;
		END IF;
		
		--	Clock movement activated
		IF rising_edge( clk_5_vga ) THEN
			IF Hactive_5 = '1' THEN
				line_count_H := line_count_H + 1;
			ELSE
				line_count_H := 0;
			END IF;
		END IF;
		
		
		IF dena_5 = '1' THEN
				
				CASE line_count_V IS
						WHEN 0 to 479 =>
							CASE line_count_H IS
								WHEN 0 to 525 =>
									--	Línea vertical
									IF (line_count_V > (yaxis_5 - altura_5 / 2) AND line_count_V < (yaxis_5 + altura_5 / 2) ) THEN
										R_5 <= ( OTHERS => '0');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '1');
									--	Línea horizontal 
									ELSIF (line_count_H > (xaxis_5 - ancho_5 / 2) AND line_count_H < (xaxis_5 + ancho_5 / 2) )  THEN
										R_5 <= ( OTHERS => '0');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '1');
									--	Estábamos haciendo pruebas y vimos que salió el logo de smash, así que lo dejamos.
									ELSE
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '1');
										B_5 <= ( OTHERS => '1');
									end IF;
								WHEN OTHERS =>
									R_5 <= ( OTHERS => '1');
									G_5 <= ( OTHERS => '1');
									B_5 <= ( OTHERS => '1');
							END CASE;
							WHEN OTHERS =>
								R_5 <= ( OTHERS => '1');
								G_5 <= ( OTHERS => '1');
								B_5 <= ( OTHERS => '1');
					END CASE;
				ELSE
					R_5 <= ( OTHERS => '0');
					G_5 <= ( OTHERS => '0');
					B_5 <= ( OTHERS => '0');
				END IF;
		END PROCESS;
		
		PROCESS ( clk_figura_5 )
		BEGIN
			--	Switches response on clock
			IF ( rising_edge(clk_figura_5) ) THEN
				--	Movimiento horizontal negativo
				IF (x0_5 = '1' AND x1_5 = '0') THEN
					xaxis_5 <= xaxis_5 - 1;
				--	Movimiento horizontal positivo
				ELSIF (x0_5 = '0' AND x1_5 = '1') THEN
					xaxis_5 <= xaxis_5 + 1;
				END IF;
				--	Movimiento vertical negativo
				IF (y0_5 = '1' AND y1_5 = '0') THEN
					yaxis_5 <= yaxis_5 - 1;
				--	Movimiento vertical positivo
				ELSIF (y0_5 = '0' AND y1_5 = '1') THEN
					yaxis_5 <= yaxis_5 + 1;
				END IF;
			END IF;
			
	
		END PROCESS;	
	
END ARCHITECTURE;