


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


ENTITY VGA_5 IS
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
		x0_5, x1_5, y0_5, y1_5, Srst_5: IN	std_logic;
		H_sync_5, V_sync_5: 	OUT	std_logic;
		BLANKn_5, SYNCn_5 : 	OUT 	std_logic;
		R_5, G_5, B_5: 			OUT 	std_logic_vector(3 DOWNTO 0);
		b : IN std_logic;
		
		t : out std_logic;
		rst, key0: in std_logic);
END ENTITY;

ARCHITECTURE behavior OF VGA_5 IS

	SIGNAL Hsync_5, Vsync_5, Hactive_5, Vactive_5, dena_5, clk_5_vga:	std_logic;
	SIGNAL clk_figura_5: STD_LOGIC;
	
	SIGNAL m	: natural := 1;

	SIGNAL xaxis_5: natural := 600;
	SIGNAL yaxis_5: natural := 400;
	
	SIGNAL xaxiss_5:natural := 60;
	SIGNAL yaxiss_5:natural := 150;
	
	--signal yaxis_1: natural ;
	--signal yaxis_1: natural;
	
	constant xaxiss: natural := 50;
	constant yaxiss: natural := 350;
	
	constant xaxisss: natural := 600;
	constant yaxisss: natural := 400;
	
	constant altura_5 : natural := 40;
	constant ancho_5 : natural := 40;
	
	constant alturaS : natural := 38;
	constant anchoS : natural := 58;
	
	SIGNAL contador_5 : POSITIVE;
	signal stop : natural;
	
	type cuadro_matrix is array(260 to 640) of integer;
	signal matrix_y2 : cuadro_matrix;
	
	type y_matrix is array(0 to 640) of integer;
	signal matrix : y_matrix;
	
	type x_matrix is array(0 to 640) of integer;
	signal matrix2 : x_matrix;
	
	type ESTADOS_5 is (S1_5, S2_5, S3_5);
	signal ESTADO_5, SIG_ESTADO_5 : ESTADOS_5;
	
BEGIN
-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------		
	
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
					IF( contador_5 = 300000 ) THEN
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
	
	PROCESS(clk_5, Hsync_5, Vactive_5, Hactive_5, clk_5_vga, dena_5, b,  x0_5, x1_5, y0_5, y1_5, Srst_5 )
		type SP_statetype is (Menu, Nivel_1, Nivel_2);
		variable SP_state : SP_statetype;
		variable vida : NATURAL := 3;
		VARIABLE line_count_V:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		VARIABLE line_count_H: natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		variable cont : natural range 171 to 229;
		variable wi: integer;
		constant ww: integer := yaxiss+alturaS/2+altura_5/2-1;
		constant yy: integer := yaxiss-alturaS/2-altura_5/2-1;
		constant xx: integer := xaxiss+anchoS/2+ancho_5/2-1;
		constant zz: integer := xaxiss-anchoS/2-ancho_5/2-1;
		
		

		
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
		
		if (rising_edge(clk_5)) THEN
		if (rst = '1') then
			SP_state := Menu;
		else
			case SP_state is
				when Menu =>
					if ((not b) = '1') then 
						SP_state := Menu;
					ELSIF (b ='1') then 
						SP_state := Nivel_1;
					end if;
					
				when Nivel_1 =>
					if ( m = 1) then 
						SP_state := Nivel_1;
					elsif (m = 2) then 
						SP_state := Nivel_2;
					elsif (vida = 0) then
						SP_state := Menu;
					end if;
					
				when Nivel_2 =>
					if (m = 2) then
						SP_state := Nivel_2;
					elsif ((m = 1) or (vida = 0)) then
						SP_state := Nivel_1;
					END IF;
				WHEN OTHERS =>
					SP_state := Menu;
					
			end case;
		end if;
			case SP_state is
				when Menu =>
					IF dena_5 = '1' THEN
						CASE line_count_V IS
						WHEN 0 to 479 =>
								R_5 <= ( OTHERS => '1');
								G_5 <= ( OTHERS => '1');
								B_5 <= ( OTHERS => '1');
						WHEN OTHERS =>
								R_5 <= ( OTHERS => '1');
								G_5 <= ( OTHERS => '1');
								B_5 <= ( OTHERS => '1');
						END CASE;
					else
								R_5 <= ( OTHERS => '0');
								G_5 <= ( OTHERS => '0');
								B_5 <= ( OTHERS => '0');
						
					END IF;		
				WHEN Nivel_1 =>
					IF dena_5 = '1' THEN
						CASE line_count_V IS
								WHEN 0 to 479 =>
									CASE line_count_H IS
										WHEN 0 to 525 =>
											--	Línea vertical
											IF (line_count_V > (yaxis_5 - altura_5 / 2) AND line_count_V < (yaxis_5 + altura_5 / 2) ) and (line_count_H > (xaxis_5 - ancho_5 / 2) AND line_count_H < (xaxis_5 + ancho_5 / 2) )  THEN
												R_5 <= ( OTHERS => '0');
												G_5 <= ( OTHERS => '0');
												B_5 <= ( OTHERS => '1');
												
													
													for i in 360 to 640 loop
														matrix(i) <= i;
														if (i > 79 and i < 171)  then
														
														----- horizontal
															matrix2(i) <= i;
														end if;
													
													end loop;
											
													for i in 0 to 221 loop
														matrix(i) <= i;
													
														if (i > 79 and i < 171)  then
														---- horizontal
															matrix2(i) <= i;
														end if;
													
														--	Cambia el color
														if (((yaxis_5) = matrix(yaxis_5)) and (xaxis_5 = matrix2(xaxis_5))) then
															
															R_5 <= ( OTHERS => '1');
															G_5 <= ( OTHERS => '0');
															B_5 <= ( OTHERS => '0');
															
															stop <= 1;
														else 
															stop <= 0;
														end if;
													
													end loop;
											--	Cuadrado
									ELSIF (line_count_V > (yaxiss - alturaS / 2) AND line_count_V < (yaxiss + alturaS / 2) ) AND (line_count_H > (xaxiss - anchoS / 2) AND line_count_H < (xaxiss + anchoS / 2) )  THEN
										R_5 <= ( OTHERS => '0');
										G_5 <= ( OTHERS => '1');
										B_5 <= ( OTHERS => '0');
										if (xaxis_5 = 50 or yaxis_5 = 350 ) then
											R_5 <= ( OTHERS => '0');
											G_5 <= ( OTHERS => '0');
											B_5 <= ( OTHERS => '1');	
											m <= m + 1;
											
										end if;
										
									
									ELSIF ((line_count_V > 0 AND line_count_V < 300) and (line_count_H > 100 and line_count_H <  150)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');
									
									ELSIF ((line_count_V > 150 AND line_count_V < 639) and (line_count_H > 500 and line_count_H <  550)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');										
										
										
									ELSIF ((line_count_V > 380 AND line_count_V < 639) and (line_count_H > 100 and line_count_H <  150)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');
										
									
											
									ELSIF ((line_count_V > 0 AND line_count_V < 50) and (line_count_H > 100 and line_count_H <  639)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');
--
													
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
				
				WHEN Nivel_2 =>
					IF dena_5 = '1' THEN
						CASE line_count_V IS
								WHEN 0 to 479 =>
									CASE line_count_H IS
										WHEN 0 to 525 =>
											--	Línea vertical
											IF (line_count_V > (yaxis_5 - altura_5 / 2) AND line_count_V < (yaxis_5 + altura_5 / 2) ) and (line_count_H > (xaxis_5 - ancho_5 / 2) AND line_count_H < (xaxis_5 + ancho_5 / 2) )  THEN
												R_5 <= ( OTHERS => '0');
												G_5 <= ( OTHERS => '0');
												B_5 <= ( OTHERS => '1');
												
												-- Inserting a square to certain locations
--												
													
													for i in 360 to 640 loop
														matrix(i) <= i;
														if (i > 79 and i < 171)  then
														--d = d+1;  or (i > 99 and i < 640)
														
														------(i > 79 and i < 171) ---- horizontal
															matrix2(i) <= i;
														end if;
														
													end loop;
											
										
											
													for i in 0 to 221 loop
														matrix(i) <= i;
													
													--d = d+1;  							or (i > 99 and i < 640)
													
														if (i > 79 and i < 171)  then
														--d = d+1;  or (i > 99 and i < 640)
														
														------(i > 79 and i < 171) ---- horizontal
															matrix2(i) <= i;
														end if;
																							
												
														--	Cambia el color
														if (((yaxiss_5) = matrix(yaxiss_5)) and (xaxiss_5 = matrix2(xaxiss_5))) then
															
															R_5 <= ( OTHERS => '1');
															G_5 <= ( OTHERS => '0');
															B_5 <= ( OTHERS => '0');
															
															stop <= 1;
														else 
															stop <= 0;
														end if;
														
														
														if ((yaxiss_5) = matrix(yaxiss_5)) and (xaxiss_5 = matrix2(xaxiss_5)) then
															
															R_5 <= ( OTHERS => '1');
															G_5 <= ( OTHERS => '0');
															B_5 <= ( OTHERS => '0');
															
															stop <= 1;
														else 
															stop <= 0;
														end if;
													end loop;
											--	Cuadrado
									ELSIF (line_count_V > (yaxisss - alturaS / 2) AND line_count_V < (yaxisss + alturaS / 2) ) AND (line_count_H > (xaxisss - anchoS / 2) AND line_count_H < (xaxisss + anchoS / 2) )  THEN
										R_5 <= ( OTHERS => '0');
										G_5 <= ( OTHERS => '1');
										B_5 <= ( OTHERS => '0');
										if (xaxis_5 = 600 or yaxis_5 = 400 ) then
												R_5 <= ( OTHERS => '0');
												G_5 <= ( OTHERS => '0');
												B_5 <= ( OTHERS => '1');	
												m <= m - 1;
												
											end if;
									
									ELSIF ((line_count_V > 0 AND line_count_V < 300) and (line_count_H > 100 and line_count_H <  150)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');
									
									ELSIF ((line_count_V > 150 AND line_count_V < 639) and (line_count_H > 500 and line_count_H <  550)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');										
										
										
									ELSIF ((line_count_V > 380 AND line_count_V < 639) and (line_count_H > 100 and line_count_H <  150)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');
										
											
									ELSIF ((line_count_V > 0 AND line_count_V < 50) and (line_count_H > 100 and line_count_H <  639)) then
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '0');
--
										
												
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
					
				WHEN OTHERS =>
					t <= '0';
		
	END CASE;
		
	END IF;
END PROCESS;

PROCESS ( clk_figura_5 )
		BEGIN
			--	Switches response on clock
			IF ( rising_edge(clk_figura_5) ) THEN
				--	Movimiento horizontal negativo
--				if (stop = 2) then
--					xaxis_5 <= 300;
				IF (b = '1') THEN
				
					IF ((x0_5 = '1' AND x1_5 = '0') AND (b = '1')) THEN
						xaxis_5 <= xaxis_5 - 1;
					--	Movimiento horizontal positivo
					ELSIF ((x0_5 = '0' AND x1_5 = '1') AND (b = '1')) THEN
						xaxis_5 <= xaxis_5 + 1;
					END IF;
					if ((stop = 1) AND (b = '1')) then
						yaxis_5 <= 400;
						xaxis_5 <= 600;
					--	Movimiento vertical negativo
					ELSIF ((y0_5 = '1' AND y1_5 = '0') AND (b = '1')) THEN
						yaxis_5 <= yaxis_5 - 1;
					--	Movimiento vertical positivo
					ELSIF ((y0_5 = '0' AND y1_5 = '1') AND (b = '1')) THEN
						yaxis_5 <= yaxis_5 + 1;
					END IF;
				ELSE
					yaxis_5 <= yaxis_5;
					xaxis_5 <= xaxis_5;
				
				END IF;
			END IF;
END PROCESS;

END ARCHITECTURE;





































--LIBRARY 	ieee;
--USE 		ieee.std_logic_1164.all;
--USE 		ieee.std_logic_arith.all;
--use 		IEEE.numeric_std.all;
--
----	Equipo 5
----	Practica 4.1
----	Andrés Sarellano
----	Luis Ángel Ramiro
----	Jesús Rodríguez
----	Izel Ávila
--
--
--
--ENTITY VGA_5 IS
--	GENERIC(
--		H_LOW_5:	natural	:= 96; --Hpulse
--		HBP_5: 		natural 	:= 48; --HBP_5
--		H_HIGH_5:	natural 	:= 640; --Hactive_5
--		HFP_5: 		natural  := 16; --HFP_5
--		V_LOW_5: 	natural  := 2; --Vpulse
--		VBP_5: 		natural	:= 33; --VBP_5
--		V_HIGH_5: 	natural  := 480; --Vactive_5
--		VFP_5: 		natural	:= 10 --VFP_5
--	); 
--	PORT(
--		clk_5: 					IN 	std_logic; --50MHz in our board
--		x0_5, x1_5, y0_5, y1_5, Srst_5: IN	std_logic;
--		H_sync_5, V_sync_5: 	OUT	std_logic;
--		BLANKn_5, SYNCn_5 : 	OUT 	std_logic;
--		R_5, G_5, B_5: 			OUT 	std_logic_vector(3 DOWNTO 0)
--	);
--END ENTITY;
--
--ARCHITECTURE behavior OF VGA_5 IS
--
--	SIGNAL Hsync_5, Vsync_5, Hactive_5, Vactive_5, dena_5, clk_5_vga:	std_logic;
--	SIGNAL clk_figura_5: STD_LOGIC;
--	
--	
--
--	SIGNAL xaxis_5: natural := 300;
--	SIGNAL yaxis_5: natural := 200;
--	
--	--signal yaxis_1: natural ;
--	--signal yaxis_1: natural;
--	
--	constant xaxiss: natural := 200;
--	constant yaxiss: natural := 100;
--	
--	constant altura_5 : natural := 40;
--	constant ancho_5 : natural := 40;
--	
--	constant alturaS : natural := 38;
--	constant anchoS : natural := 58;
--	
--	SIGNAL contador_5 : POSITIVE;
--	signal stop : natural;
--	
--	type cuadro_matrix is array(0 to 479) of integer;
--	signal matrix_cuadros : cuadro_matrix;
--	
--	type y_matrix is array(0 to 640, 0 to 1) of integer;
--	signal matrix : y_matrix;
--	
--	type x_matrix is array(0 to 480) of integer;
--	signal matrix2 : x_matrix;
--
--	
--BEGIN
---------------------------------------------------------
----Part 1: CONTROL GENERATOR
---------------------------------------------------------		
--	
--		--Static signals for DACs:
--		BLANKn_5 	<= '1'; --no direct blanking
--		SYNCn_5 	<= '0'; --no sync on green
--		
--		--	Crear reloj
--		PROCESS( clk_5 )
--		BEGIN
--			IF rising_edge( clk_5 ) THEN 
--				clk_5_vga <= not clk_5_vga;
--				contador_5 <= contador_5 + 1;
--					-- ( 50MHz/1Hz ) * 0.1
--					IF( contador_5 = 1500000 ) THEN
--						clk_figura_5   <= NOT clk_figura_5;
--						contador_5 <= 1;
--					END IF;
--			END IF;
--		END PROCESS;
--	
--		--Horizontal signals generation:
--		PROCESS( clk_5_vga )
--			VARIABLE Hcontador_5:	natural RANGE 0 to H_LOW_5 + HBP_5 + H_HIGH_5 + HFP_5;
--		BEGIN
--			IF rising_edge( clk_5_vga ) THEN 
--				Hcontador_5 := Hcontador_5 + 1;
--				IF Hcontador_5 = H_LOW_5 THEN 
--					Hsync_5 	<= '1';
--				ELSIF Hcontador_5 = H_LOW_5 + HBP_5 THEN 
--					Hactive_5 	<= '1';
--				ELSIF Hcontador_5 = H_LOW_5 + HBP_5 + H_HIGH_5 THEN 
--					Hactive_5 	<= '0';
--				ELSIF Hcontador_5 = H_LOW_5 + HBP_5 + H_HIGH_5 + HFP_5 THEN 
--					Hsync_5 	<= '0'; 
--					Hcontador_5 	:=  0;
--				END IF;
--			END IF;
--		END PROCESS;
--		
--		--Vertical signals generation:
--		PROCESS( Hsync_5 )
--			
--			VARIABLE Vcontador_5:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
--		BEGIN
--			IF rising_edge( Hsync_5 ) THEN 
--				Vcontador_5 := Vcontador_5 + 1;
--				IF Vcontador_5 = V_LOW_5 THEN 
--					Vsync_5 	<= '1';
--				ELSIF Vcontador_5 = V_LOW_5 + VBP_5 THEN 
--					Vactive_5 	<= '1';
--				ELSIF Vcontador_5 = V_LOW_5 + VBP_5 + V_HIGH_5 THEN 
--					Vactive_5 	<= '0';
--				ELSIF Vcontador_5 = V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5 THEN 
--					Vsync_5 	<= '0'; 
--					Vcontador_5 	:=  0;
--				END IF;
--			END IF;
--		END PROCESS;
--	
--		H_sync_5 <= Hsync_5;
--		V_sync_5 <= Vsync_5;
--	
--		---Display enable generation:
--		dena_5 <= Hactive_5 and Vactive_5;
--		
---------------------------------------------------------
----Part 2: IMAGE GENERATOR
---------------------------------------------------------	
--	
--	PROCESS( Hsync_5, Vactive_5, Hactive_5, clk_5_vga, clk_5, dena_5, x0_5, x1_5, y0_5, y1_5, Srst_5 )
--		VARIABLE line_count_V:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
--		VARIABLE line_count_H: natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
--		variable cont : natural range 171 to 229;
--		variable wi, a, b, c, d : integer;
--		constant ww: integer := yaxiss+alturaS/2+altura_5/2-1;
--		constant yy: integer := yaxiss-alturaS/2-altura_5/2-1;
--		constant xx: integer := xaxiss+anchoS/2+ancho_5/2-1;
--		constant zz: integer := xaxiss-anchoS/2-ancho_5/2-1;
--		
--		
--
--		
------		--	Limite inferior Vertical
------		VARIABLE limInfV: integer := 180;
------		VARIABLE limSupV: integer := 300;
------		--	Limite inferior Horizontal
------		VARIABLE limInfH: integer :=240;
------		VARIABLE limSupH: integer :=360;
--	BEGIN
--
--			
--		IF rising_edge( Hsync_5 ) THEN
--			IF Vactive_5 = '1' THEN
--				line_count_V := line_count_V + 1;
--			ELSE
--				line_count_V := 0;
--			END IF;
--		END IF;
--		
--		--	Clock movement activated
--		IF rising_edge( clk_5_vga ) THEN
--			IF Hactive_5 = '1' THEN
--				line_count_H := line_count_H + 1;
--			ELSE
--				line_count_H := 0;
--			END IF;
--		END IF;
--		
--		
--		IF dena_5 = '1' THEN
--
--				
--				CASE line_count_V IS
--						WHEN 0 to 479 =>
--							CASE line_count_H IS
--								WHEN 0 to 525 =>
--									--	Línea vertical
--									IF (line_count_V > (yaxis_5 - altura_5 / 2) AND line_count_V < (yaxis_5 + altura_5 / 2) ) and (line_count_H > (xaxis_5 - ancho_5 / 2) AND line_count_H < (xaxis_5 + ancho_5 / 2) )  THEN
--										R_5 <= ( OTHERS => '0');
--										G_5 <= ( OTHERS => '0');
--										B_5 <= ( OTHERS => '1');
--										
--										-- Inserting a square to certain locations
----										for i in yy to ww loop
----											--d = d+1;
----											matrix(i,0) <= i;
----											
----											for wi in zz to xx loop
----											matrix(wi,1) <= wi;
----											end loop;
----											
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '0');
----												
----											
----											if (((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1))) then
----												
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '1');
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----											end if;
----										end loop;
--									--	Cuadrado
--									ELSIF (line_count_H > 100 AND line_count_H < 150 ) AND (line_count_V > 450 AND line_count_V < 600 ) THEN
--										R_5 <= ( OTHERS => '0');
--										G_5 <= ( OTHERS => '1');
--										B_5 <= ( OTHERS => '0');
--									
----									
----									for i in 0 to 150 loop -- x 
----											--d = d+1;
----											matrix(i,0) <= i;
----											
----											for wi in 450 to 600 loop --y
----											matrix(wi,1) <= wi;
----											end loop;
----											
--											
----											
----											if (((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1))) then
----												
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '1');
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----											end if;
----										end loop;
----										
--										
--										
----										
----										ELSIF (line_count_V > 100 AND line_count_V < 150 ) AND (line_count_H > 0 AND line_count_H < 250 ) THEN
----										R_5 <= ( OTHERS => '0');
----										G_5 <= ( OTHERS => '1');
----										B_5 <= ( OTHERS => '0');
----									
----									
----									for i in 100 to 150 loop
----											--d = d+1;
----											matrix(i,0) <= i;
----											
----											for wi in 0 to 250 loop
----											matrix(wi,1) <= wi;
----											end loop;
----											
----											if (((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1))) then
----												
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '1');
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----											end if;
----										end loop;
----										
----									ELSIF ((line_count_H > 143 AND line_count_H < 269) and (line_count_V > 80 and line_count_V <  180)) then
----									
----										R_5 <= ( OTHERS => '1');
----										G_5 <= ( OTHERS => '0');
----										B_5 <= ( OTHERS => '1');
----										
----										
----
----										ELSIF ((line_count_H > 150 AND line_count_H < 480) and (line_count_V > 500 and line_count_V <  600)) THEN
----										R_5 <= ( OTHERS => '0');
----										G_5 <= ( OTHERS => '1');
----										B_5 <= ( OTHERS => '0');
----									
----									
----									for i in 150 to 480 loop
----											--d = d+1;
----											matrix(i,0) <= i;
----											
----											for wi in 500 to 600 loop
----											matrix(wi,1) <= wi;
----											end loop;
----											
----											if (((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1))) then
----												
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '1');
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----											end if;
----										end loop;
----
----										ELSIF ((line_count_H > 150 AND line_count_H < 480) and (line_count_V > 250 and line_count_V <  300)) THEN
----										R_5 <= ( OTHERS => '0');
----										G_5 <= ( OTHERS => '1');
----										B_5 <= ( OTHERS => '0');
----									
----									
----									for i in 150 to 480 loop
----											--d = d+1;
----											matrix(i,0) <= i;
----											
----											for wi in 500 to 600 loop
----											matrix(wi,1) <= wi;
----											end loop;
----											
----											if (((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1))) then
----												
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '1');
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----											end if;
----										end loop;
----										
----										
----										
----										ELSIF ((line_count_H > 300 AND line_count_H < 350) and (line_count_V > 400 and line_count_V < 600)) THEN
----										R_5 <= ( OTHERS => '0');
----										G_5 <= ( OTHERS => '1');
----										B_5 <= ( OTHERS => '0');
----									
----									
----									for i in 300 to 350 loop
----											--d = d+1;
----											matrix(i,0) <= i;
----											
----											for wi in 400 to 600 loop
----											matrix(wi,1) <= wi;
----											end loop;
----											
----											if (((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1))) then
----												
----												R_5 <= ( OTHERS => '0');
----												G_5 <= ( OTHERS => '1');
----												B_5 <= ( OTHERS => '1');
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----											end if;
----										end loop;
------										
----									ELSIF ((line_count_V > 400 AND line_count_V < 450) and (line_count_H > 400 and line_count_H < 500)) THEN
----										R_5 <= ( OTHERS => '0');
----										G_5 <= ( OTHERS => '1');
----										B_5 <= ( OTHERS => '0');
----
----
--
--
--
--
----									for i in 143 to 269  loop
----											--d = d+1;
----											matrix(i) <= i;
----											
----											for wi in 80 to 180 loop
----											matrix2(wi) <= wi;
----											end loop;
----										
----										if ((yaxis_5) = matrix(yaxis_5)) and (xaxis_5 = matrix2(xaxis_5)) then							
----												
----												stop <= 1;
----											else 
----												stop <= 0;
----									end if;
----									end loop;
----										
----										
----									elsif ((yaxis_5 = matrix) and (xaxis_5 = xaxiss)) then
----										R_5 <= ( OTHERS => '0');
----										G_5 <= ( OTHERS => '1');
----										B_5 <= ( OTHERS => '1');
--
--
--
--
--
--										
--									--	Estábamos haciendo pruebas y vimos que salió el logo de smash, así que lo dejamos.
--									ELSE
--										R_5 <= ( OTHERS => '1');
--										G_5 <= ( OTHERS => '1');
--										B_5 <= ( OTHERS => '1');
--									end IF;
--								WHEN OTHERS =>
--									R_5 <= ( OTHERS => '1');
--									G_5 <= ( OTHERS => '1');
--									B_5 <= ( OTHERS => '1');
--							END CASE;
--							WHEN OTHERS =>
--								R_5 <= ( OTHERS => '1');
--								G_5 <= ( OTHERS => '1');
--								B_5 <= ( OTHERS => '1');
--					END CASE;
--				ELSE
--					R_5 <= ( OTHERS => '0');
--					G_5 <= ( OTHERS => '0');
--					B_5 <= ( OTHERS => '0');
--				END IF;
--		END PROCESS;
--		
--		PROCESS ( clk_figura_5 )
--		BEGIN
--			--	Switches response on clock
--			IF ( rising_edge(clk_figura_5) ) THEN
--				--	Movimiento horizontal negativo
--				if (stop = 2) then
--					xaxis_5 <= xaxis_5;
--				elsIF (x0_5 = '1' AND x1_5 = '0') THEN
--					xaxis_5 <= xaxis_5 - 1;
--				--	Movimiento horizontal positivo
--				ELSIF (x0_5 = '0' AND x1_5 = '1') THEN
--					xaxis_5 <= xaxis_5 + 1;
--				END IF;
--				if (stop = 1) then
--					yaxis_5 <= yaxis_5;
--				--	Movimiento vertical negativo
--				ELSIF (y0_5 = '1' AND y1_5 = '0') THEN
--					yaxis_5 <= yaxis_5 - 1;
--				--	Movimiento vertical positivo
--				ELSIF (y0_5 = '0' AND y1_5 = '1') THEN
--					yaxis_5 <= yaxis_5 + 1;
--				END IF;
--				
--			END IF;
--			
--	
--		END PROCESS;	
--	
--END ARCHITECTURE;