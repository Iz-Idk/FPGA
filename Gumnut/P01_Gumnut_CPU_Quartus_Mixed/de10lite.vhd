LIBRARY  ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;


ENTITY de10lite IS
PORT(
CLOCK_50 :  IN std_logic;

SW :  IN  std_logic_vector( 9 DOWNTO 0 );
BLANKn_5, SYNCn_5 : out std_logic;
VGA_HS : OUT std_logic;
VGA_VS : OUT std_logic;
VGA_R : OUT std_logic_vector( 3 DOWNTO 0 );
VGA_G : OUT std_logic_vector( 3 DOWNTO 0 );
VGA_B : OUT std_logic_vector( 3 DOWNTO 0 );
HEX0 : OUT std_logic_vector( 6 DOWNTO 0 );
HEX5 : OUT std_logic_vector( 6 DOWNTO 0 );
KEY :  IN  std_logic_vector( 1 DOWNTO 0 );
LEDR :  OUT std_logic_vector( 9 DOWNTO 0 )
);
END de10lite;
ARCHITECTURE behavior OF de10lite IS

signal display, display2: std_logic_vector(3 downto 0);


signal colision : std_logic;




component gumnut_with_mem IS
generic ( 
IMem_file_name : string := "gasm_text.dat";
DMem_file_name : string := "gasm_data.dat";
         debug : boolean := false );
port ( clk_i : in std_logic;
         rst_i : in std_logic;
         -- I/O port bus
         port_cyc_o : out std_logic;
         port_stb_o : out std_logic;
         port_we_o : out std_logic;
         port_ack_i : in std_logic;
         port_adr_o : out std_logic_vector(7 downto 0);
         port_dat_o : out std_logic_vector(7 downto 0);
         port_dat_i : in std_logic_vector(7 downto 0);
         -- Interrupts
         int_req : in std_logic;
         int_ack : out std_logic );
end COMPONENT gumnut_with_mem;

component BCD_7_segmentos IS
	PORT(
		x: in STD_LOGIC_VECTOR ( 3 DOWNTO 0);
		segs: out STD_LOGIC_VECTOR( 6 DOWNTO 0)
		);
END component;

--component VGA_5 IS
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
--		PORT(
--		clk_5 : 					IN 	std_logic; --50MHz in our board
--		sw : IN	std_logic_vector (9 downto 0);
--		H_sync_5, V_sync_5: 	OUT	std_logic;
--		BLANKn_5, SYNCn_5 : 	OUT 	std_logic;
--		R_5, G_5, B_5: 			buffer 	std_logic_vector(3 DOWNTO 0);
--		HEX0 : OUT std_logic_vector( 6 DOWNTO 0 );
--		HEX5 : OUT std_logic_vector( 6 DOWNTO 0 );
--		keys : in std_logic_vector(1 downto 0);
--		LEDR : OUT std_logic_vector( 9 DOWNTO 0 )
--		
--	);
--END component;

----- GENERIC DEL VGA

signal		H_LOW_5:	natural	:= 96; --Hpulse
signal		HBP_5: 		natural 	:= 48; --HBP_5
signal		H_HIGH_5:	natural 	:= 640; --Hactive_5
signal		HFP_5: 		natural  := 16; --HFP_5
signal		V_LOW_5: 	natural  := 2; --Vpulse
signal		VBP_5: 		natural	:= 33; --VBP_5
signal		V_HIGH_5: 	natural  := 480; --Vactive_5
signal		VFP_5: 		natural	:= 10 ;--VFP_5




SIGNAL Hsync_5, Vsync_5, Hactive_5, Vactive_5, dena_5, clk_5_vga, b:	std_logic;
	SIGNAL clk_figura_5: STD_LOGIC;
	
	------ Coordenadas de los cuadros ------------------------------------------------
SIGNAL xaxis_5: natural := 600;
	SIGNAL yaxis_5: natural := 400;
	
	SIGNAL xaxiss_5:natural := 60;
	SIGNAL yaxiss_5:natural := 150;
	
	constant xaxiss: natural := 50;
	constant yaxiss: natural := 350;
	
	constant xaxisss: natural := 600;
	constant yaxisss: natural := 400;
	
	constant altura_5 : natural := 40;
	constant ancho_5 : natural := 40;
	
	constant alturaS : natural := 38;
	constant anchoS : natural := 58;
	
	
	------ Para el portmap del de10lite ------------------------------------------------
	
	signal reemplazo : std_logic_vector (4 downto 0);
	--signal keys : std_logic_vector(1 downto 0);
	--signal colision : std_logic;
	--signal r,g,b: std_logic_vector(3 downto 0);
	
	






SIGNAL  clk_i, rst_i, 
port_cyc_o, port_stb_o, 
port_we_o, port_ack_i, 
int_req, int_ack, H_sync_5, V_sync_5, t :  std_logic;
signal R_5, G_5, B_5 : std_logic_vector(3 downto 0);
SIGNAL  port_dat_o, port_dat_i : std_logic_vector( 7 downto 0 );
SIGNAL   port_adr_o : std_logic_vector( 7 DOWNTO 0 );
signal x0_5, x1_5, y0_5, y1_5, Srst_5:	std_logic;
--signal BLANKn_5, SYNCn_5, data_i: std_logic;
signal m: natural := 0;
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

clk_i  <= CLOCK_50;
rst_i  <= not KEY( 0 );
--button_i <= KEY(1);
port_ack_i  <= '1';



--Static signals for DACs:
		BLANKn_5 	<= '1'; --no direct blanking
		SYNCn_5 	<= '0'; --no sync on green
		

	
	gumnut : 		COMPONENT gumnut_with_mem 
							PORT MAP(
							clk_i,
							rst_i,
							port_cyc_o,
							port_stb_o,
							port_we_o,
							port_ack_i,
							port_adr_o (7 downto 0),
							port_dat_o (7 downto 0),
							port_dat_i (7 downto 0),
							int_req,
							int_ack);
							
--	vga : component VGA_5
--		port map(
--		CLOCK_50 ,
--		SW ,
--	VGA_HS,
--	VGA_VS ,
--	BLANKn_5, 
--	SYNCn_5,
--	VGA_R ,	
--	VGA_G ,	
--	VGA_B ,
--	HEX0 ,		
--	HEX5 ,
--	KEY ,
--	LEDR );
			--aaa : de10lite port map(
--CLOCK_50 => clk_5,
--KEY => keys,
--SW => sw,
--VGA_HS => H_sync_5,
--VGA_VS => V_sync_5,
--VGA_R => R_5,
--VGA_G => G_5,
--VGA_B => B_5,
--HEX0 => HEX0,
--HEX5 => HEX5,
--LEDR => LEDR
--);
		
--
--	leds			:	process(clk_i)
--							begin
--							if rising_edge(clk_i) then
--								if port_adr_o = "00000001" and port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '1' then
--									--LEDR(7 downto 0) <= port_dat_o(7 downto 0);
--									display2(3 downto 0) <= port_dat_o(3 downto 0);
--								end if;
--							end if;
--						end process;
--	hexs			:	process(clk_i)
--							begin
--							if rising_edge(clk_i) then
--								if port_adr_o = "00000010" and port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '1' then
--									display(3 downto 0) <= port_dat_o(3 downto 0);
--								end if;
--							end if;
--						end process;
--						
--	buttom      :	process(clk_i)
--						begin
--								if rising_edge(clk_i) then
--									--port_dat_i(0) <= '0';	
--								if port_adr_o = "00000000" and port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '0' then
--									port_dat_i(0) <= colision;
--								end if;
--							end if;
--							--colision <= '0';
--						end process;
--						
--				
--	bcd: BCD_7_segmentos port map (display, HEX0);
--	
	--aaa : de10lite port map(
--CLOCK_50 => clk_5,
--KEY => keys,
--SW => sw,
--VGA_HS => H_sync_5,
--VGA_VS => V_sync_5,
--VGA_R => R_5,
--VGA_G => G_5,
--VGA_B => B_5,
--HEX0 => HEX0,
--HEX5 => HEX5,
--LEDR => LEDR
--);



--	vgaa: VGA_5 port map(
--	CLOCK_50 ,
--	SW ,
--	VGA_HS,
--	VGA_VS ,
--	BLANKn_5, 
--	SYNCn_5,
--	VGA_R ,	
--	VGA_G ,
--	VGA_B ,
--	HEX0 ,
--	HEX5 ,
--	KEY ,
--	LEDR 
--	
--	
--	);








		
		--	Crear reloj
		PROCESS( CLOCK_50 )
		BEGIN
			IF rising_edge( CLOCK_50 ) THEN 
				clk_5_vga <= not clk_5_vga;
				contador_5 <= contador_5 + 1;
					-- ( 50MHz/1Hz ) * 0.1
					IF( contador_5 = 1500000 ) THEN
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
	
		VGA_HS <= Hsync_5;
		VGA_VS <= Vsync_5;
	
		---Display enable generation:
		dena_5 <= Hactive_5 and Vactive_5;
		
		
		
		
		
-------------------------------------------------------
--Part 2: IMAGE GENERATOR
-------------------------------------------------------	
	
	PROCESS(CLOCK_50, Hsync_5, Vactive_5, Hactive_5, clk_5_vga, dena_5, b,  sw(3 downto 0) )
		type SP_statetype is (Menu, Nivel_1, Nivel_2);
		variable SP_state : SP_statetype;
		variable vida : NATURAL := 5;
		
		VARIABLE line_count_V:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		VARIABLE line_count_H: natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		variable cont : natural range 171 to 229;
		variable wi: integer;
		constant ww: integer := yaxiss+alturaS/2+altura_5/2-1;
		constant yy: integer := yaxiss-alturaS/2-altura_5/2-1;
		constant xx: integer := xaxiss+anchoS/2+ancho_5/2-1;
		constant zz: integer := xaxiss-anchoS/2-ancho_5/2-1;
		
		

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
		
		if (rising_edge(CLOCK_50)) THEN
		if (rst_i = '1') then
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
														if (((yaxis_5) = matrix(yaxis_5)) and (xaxis_5 = matrix2(xaxis_5))) then
															
															R_5 <= ( OTHERS => '1');
															G_5 <= ( OTHERS => '0');
															B_5 <= ( OTHERS => '0');
															colision <= '1';
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
				
					IF ((sw(0) = '1' AND sw(1) = '0') AND (b = '1')) THEN
						xaxis_5 <= xaxis_5 - 1;
					--	Movimiento horizontal positivo
					ELSIF ((sw(0) = '0' AND sw(1) = '1') AND (b = '1')) THEN
						xaxis_5 <= xaxis_5 + 1;
					END IF;
					if ((stop = 1) AND (b = '1')) then
						yaxis_5 <= 400;
						xaxis_5 <= 600;
					--	Movimiento vertical negativo
					ELSIF ((sw(2) = '1' AND sw(3) = '0') AND (b = '1')) THEN
						yaxis_5 <= yaxis_5 - 1;
					--	Movimiento vertical positivo
					ELSIF ((sw(2) = '0' AND sw(3) = '1') AND (b = '1')) THEN
						yaxis_5 <= yaxis_5 + 1;
					END IF;
				ELSE
					yaxis_5 <= yaxis_5;
					xaxis_5 <= xaxis_5;
				
				END IF;
			END IF;
END PROCESS;
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
--	
--	PROCESS( Hsync_5, Vactive_5, Hactive_5, clk_5_vga, CLOCK_50, dena_5, sw(3 downto 0) )
--		VARIABLE line_count_V:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
--		VARIABLE line_count_H: natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
--		variable cont : natural range 171 to 229;
--
--	
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
--										VGA_R <= ( OTHERS => '0');
--										VGA_G <= ( OTHERS => '0');
--										VGA_B <= ( OTHERS => '1');
--										end if;
--								WHEN OTHERS =>
--									VGA_R <= ( OTHERS => '1');
--									VGA_G <= ( OTHERS => '1');
--									VGA_B <= ( OTHERS => '1');
--							END CASE;
--							
--							WHEN OTHERS =>
--								VGA_R <= ( OTHERS => '1');
--								VGA_G <= ( OTHERS => '1');
--								VGA_B <= ( OTHERS => '1');
--					END CASE;
--				ELSE
--					VGA_R <= ( OTHERS => '0');
--					VGA_G <= ( OTHERS => '0');
--					VGA_B <= ( OTHERS => '0');
--				END IF;
--		END PROCESS;
--		

END behavior;