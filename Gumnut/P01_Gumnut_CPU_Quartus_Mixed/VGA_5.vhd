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
		clk_5 : 					IN 	std_logic; --50MHz in our board
		sw : IN	std_logic_vector (9 downto 0);
		H_sync_5, V_sync_5: 	OUT	std_logic;
		BLANKn_5, SYNCn_5 : 	OUT 	std_logic;
		R_5, G_5, B_5: 			buffer 	std_logic_vector(3 DOWNTO 0);
		HEX0 : OUT std_logic_vector( 6 DOWNTO 0 );
		HEX5 : OUT std_logic_vector( 6 DOWNTO 0 );
		keys : in std_logic_vector(1 downto 0);
		LEDR : OUT std_logic_vector( 9 DOWNTO 0 )
		
	);
	

END ENTITY;

ARCHITECTURE behavior OF VGA_5 IS

	SIGNAL Hsync_5, Vsync_5, Hactive_5, Vactive_5, dena_5, clk_5_vga:	std_logic;
	SIGNAL clk_figura_5: STD_LOGIC;
	
	------ Coordenadas de los cuadros ------------------------------------------------

	SIGNAL xaxis_5: natural := 300;
	SIGNAL yaxis_5: natural := 200;
	
	constant xaxiss: natural := 200;
	constant yaxiss: natural := 100;
	
	constant altura_5 : natural := 40;
	constant ancho_5 : natural := 40;
	
	constant alturaS : natural := 38;
	constant anchoS : natural := 58;
	
	SIGNAL contador_5 : POSITIVE;
	signal stop : natural;
	
	------ Para hitbox de cuadrados ------------------------------------------------
	
	type cuadro_matrix is array(0 to 479) of integer;
	signal matrix_cuadros : cuadro_matrix;
	
	type y_matrix is array(0 to 479, 0 to 1) of integer;
	signal matrix : y_matrix;
	
	type x_matrix is array(0 to 480) of integer;
	signal matrix2 : x_matrix;
	
	------ Para el portmap del de10lite ------------------------------------------------
	
	signal reemplazo : std_logic_vector (4 downto 0);
	--signal keys : std_logic_vector(1 downto 0);
	signal colision : std_logic;
	signal r,g,b: std_logic_vector(3 downto 0);
	
	
component de10lite	
PORT(
CLOCK_50 :  IN std_logic;
KEY :  IN  std_logic_vector( 1 DOWNTO 0 );
SW :  IN  std_logic_vector( 9 DOWNTO 0 );
VGA_HS : OUT std_logic;
VGA_VS : OUT std_logic;
VGA_R : OUT std_logic_vector( 3 DOWNTO 0 );
VGA_G : OUT std_logic_vector( 3 DOWNTO 0 );
VGA_B : OUT std_logic_vector( 3 DOWNTO 0 );
HEX0 : OUT std_logic_vector( 6 DOWNTO 0 );
HEX5 : OUT std_logic_vector( 6 DOWNTO 0 );
LEDR :  OUT std_logic_vector( 9 DOWNTO 0 )
);
END component;


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


SIGNAL  clk_i, rst_i, 
port_cyc_o, port_stb_o, 
port_we_o, port_ack_i, 
int_req, int_ack :  std_logic;
SIGNAL  port_dat_o, port_dat_i : std_logic_vector( 7 downto 0 );
SIGNAL   port_adr_o : std_logic_vector( 7 DOWNTO 0 );
signal display: std_logic_vector(3 downto 0);
signal HEX00 : std_logic_vector(6 downto 0);
	BEGIN
--
--clk_i  <= CLk_5;
----rst_i  <= not KEY( 0 );
--port_ack_i  <= '1';

-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------
--	PROCESS (clk_5)
--	BEGIN
--	IF (KEYs(1) = '0') THEN
--	LEDR(0) <= '1';
--	
--	LEDR(9 downto 1) <= ( OTHERS => '0');
--	
--	else 
--	LEDR(0) <= '0';
--	LEDR(9 downto 1) <= ( OTHERS => '0');
--	end if;
--	end process;
	

--		r <= R_5;
--		g <= G_5;
--		b <= B_5;
--		
--	porty : de10lite port map (
--CLOCK_50 => clk_5,
--data_i => colision,
--KEY => keys,
--SW   => x0_5 & x1_5 & y0_5 & y1_5 & Srst_5 & reemplazo,
--VGA_HS => H_sync_5,
--VGA_VS => V_sync_5,
--VGA_R => r,
--VGA_G => g,
--VGA_B => b,
--HEX0 => HEX0,
--HEX5 => HEX5,
--LEDR => LEDR);

--gumnut : 		COMPONENT gumnut_with_mem 
--							PORT MAP(
--							clk_i,
--							rst_i,
--							port_cyc_o,
--							port_stb_o,
--							port_we_o,
--							port_ack_i,
--							port_adr_o (7 downto 0),
--							port_dat_o (7 downto 0),
--							port_dat_i (7 downto 0),
--							int_req,
--							int_ack);
--					
--process(clk_i)
--	begin
--		if rising_edge(clk_i) then
--									--port_dat_i(0) <= '0';	
--			if port_adr_o = "00000000" and port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '0' then
--									port_dat_i(0) <= data_i;
--				end if;
--									
--		end if;
--end process;	
--	hexs			:	process(clk_i)
--							begin
--							if rising_edge(clk_i) then
--								if port_adr_o = "00000010" and port_cyc_o = '1' and port_stb_o = '1' and port_we_o = '1' then
--									display(3 downto 0) <= port_dat_o(3 downto 0);
--								end if;
--							end if;
--						end process;
--
--bcd	: BCD_7_segmentos  port map(display, HEX0);



--aaa : de10lite port map(
--CLOCK_50 => clk_5,
--
--SW => sw,
--VGA_HS => H_sync_5,
--VGA_VS => V_sync_5,
--VGA_R => r,
--VGA_G => g,
--VGA_B => b,
--HEX0 => HEX0,
--HEX5 => HEX5,
--KEY => keys,
--LEDR => LEDR
--);






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
	
		H_sync_5 <= Hsync_5;
		V_sync_5 <= Vsync_5;
	
		---Display enable generation:
		dena_5 <= Hactive_5 and Vactive_5;
		
		
		
		
		
-------------------------------------------------------
--Part 2: IMAGE GENERATOR
-------------------------------------------------------	
	
	PROCESS( Hsync_5, Vactive_5, Hactive_5, clk_5_vga, clk_5, dena_5, sw(3 downto 0) )
		VARIABLE line_count_V:	natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		VARIABLE line_count_H: natural RANGE 0 TO V_LOW_5 + VBP_5 + V_HIGH_5 + VFP_5;
		variable cont : natural range 171 to 229;
		variable wi, a, b, c, d : integer;
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
										for i in yy to ww loop
											--d = d+1;
											matrix(i,0) <= i;
											
											for wi in zz to xx loop
											matrix(wi,1) <= wi;
											end loop;
											
											
											
											if ((yaxis_5) = matrix(yaxis_5,0)) and (xaxis_5 = matrix(xaxis_5,1)) then
												
												R_5 <= ( OTHERS => '0');
												G_5 <= ( OTHERS => '1');
												B_5 <= ( OTHERS => '1');
												
												--stop <= 1;
												--colision <= '1';
												--data_i <= '1';
											else 
												stop <= 0;
												
											end if;
											
										end loop;
										--colision <= '0';
									--	Cuadrado
									ELSIF (line_count_V > (yaxiss - alturaS / 2) AND line_count_V < (yaxiss + alturaS / 2) ) AND (line_count_H > (xaxiss - anchoS / 2) AND line_count_H < (xaxiss + anchoS / 2) )  THEN
										R_5 <= ( OTHERS => '0');
										G_5 <= ( OTHERS => '1');
										B_5 <= ( OTHERS => '0');
									
									ELSIF ((line_count_V > 143 AND line_count_V < 269) and (line_count_H > 80 and line_count_H <  180)) then
									
										R_5 <= ( OTHERS => '1');
										G_5 <= ( OTHERS => '0');
										B_5 <= ( OTHERS => '1');
--										
--									for i in 143 to 269  loop
--											--d = d+1;
--											matrix(i) <= i;
--											
--											for wi in 80 to 180 loop
--											matrix2(wi) <= wi;
--											end loop;
--										
--										if ((yaxis_5) = matrix(yaxis_5)) and (xaxis_5 = matrix2(xaxis_5)) then							
--												
--												stop <= 1;
--											else 
--												stop <= 0;
--									end if;
--									end loop;
--										
--										
--									elsif ((yaxis_5 = matrix) and (xaxis_5 = xaxiss)) then
--										R_5 <= ( OTHERS => '0');
--										G_5 <= ( OTHERS => '1');
--										B_5 <= ( OTHERS => '1');
										
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
--					--colision <= '0';
--
--				--	Movimiento vertical positivo
--				ELSIF (y0_5 = '0' AND y1_5 = '1') THEN
--					yaxis_5 <= yaxis_5 + 1;
--				END IF;
--				
--			END IF;
--			
--	
--		END PROCESS;
	

END ARCHITECTURE;