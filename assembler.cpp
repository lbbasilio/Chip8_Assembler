#include <string>	// std::strng
#include <fstream>	// std::fstream
#include <iostream>	// std::cout
#include <sstream>	// std::stringstream
#include <algorithm>	// std::transform
#include <map>		// std::map

#define CHECKNNN( x ) \
	pos = x.find_first_not_of(hexValues + "#"); \
	if (pos != std::string::npos || x.length() != 4 || x[0] != '#' || x[1] == '#' || x[2] == '#' || x[3] == '#') { \
		std::cout << "Line " << n + 1 << ": unknown address hex value " << x << ": expected #***;\n"; \
		std::cout << line; \
		fi.close(); \
		fo.close(); \
		return -1; \
	} \
	x.erase(x.begin(), x.begin() + 1)

#define CHECKV( x ) \
	pos = x.find_first_not_of(hexValues + "V"); \
 	if (pos != std::string::npos || x.length() != 2 || x[0] != 'V' || x[1] == 'V') { \
		std::cout << "Line " << n + 1 << ": unknown register " << x << ": expected V*;\n"; \
		std::cout << line; \
		fi.close(); \
		fo.close(); \
		return -1; \
	 } \
	 x.erase(x.begin(), x.begin() + 1)

		
#define CHECKBYTE( x ) \
	pos = x.find_first_not_of(hexValues + "#"); \
	if (pos != std::string::npos || x.length() != 3 || x[0] != '#' || x[1] == '#' || x[2] == '#') { \
		std::cout << "Line " << n + 1 << ": unknown byte " << x << ": expected #**;\n"; \
		std::cout << line; \
		fi.close(); \
		fo.close(); \
		return -1; \
	} \
	x.erase(x.begin(), x.begin() + 1)


#define CHECKNIBBLE( x ) \
	pos = x.find_first_not_of(hexValues + "#"); \
	if (pos != std::string::npos || x.length() != 2 || x[0] != '#' || x[1] == '#') { \
		std::cout << "Line " << n + 1 << ": unknown nibble " << x << ": expected #*;\n"; \
		std::cout << line; \
		fi.close(); \
		fo.close(); \
		return -1; \
	} \
	x.erase(x.begin(), x.begin() + 1)

const std::string whitespaces = " \t\n";
const std::string hexValues = "0123456789ABCDEF";

void mapInit();
enum opcode {
	undefined,
	CLS,
	RET,
	JP,
	CALL,
	SE,
	SNE,
	SER,
	LD,
	ADD,
	LDR,
	OR,
	AND,
	XOR,
	ADDR,
	SUBR,
	SHR,
	SUBNR,
	SHL,
	SNER,
	LDI,
	JPV0,
	RND,
	DRW,
	SKP,
	SKNP,
	LDXDT,
	LDK,
	LDDTX,
	LDSTX,
	ADDI,
	LDLOC,
	LDBCD,
	LDMR,
	LDRM	
};
static std::map<std::string, opcode> opcodeMap;

unsigned dec(std::string hex);	// hex to dec
std::string hex(unsigned dec);	// dec to hex

void checknnn(std::string nnn);
void checkbyte(std::string byte);
void checkR(std::string R);

int main(int argc, char** argv) {
	
	std::fstream fi, fo;
	std::fstream hex_out;
	fi.open(argv[1], std::fstream::in);
	fo.open("output.mif", std::fstream::out);
	hex_out.open("output.hex", std::fstream::out | std::fstream::binary);

	if (fi.good() && fo.good()) {
		
		fo << "WIDTH = 8;\nDEPTH = 4096;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT BEGIN\n";
		mapInit(); // Initialize the opcode map

		int n = 0; // line counter


		std::string line, aux;
		std::string instr, op, VX, VY, nnn, byte, nibble;
		std::string::size_type pos;
		
		while (std::getline(fi, line) && n < 2048) {
			
			/* Trimming */
			pos = line.find_first_not_of(whitespaces);
			line.erase(0, pos);
			pos = line.find_first_of("@"); // Detects comments and empty lines
			if (pos != std::string::npos || line.empty()) continue; // Skips them
			
			pos = line.find_first_of(";"); // Searches for ;
			if (pos == std::string::npos) {
				std::cout << "Line " << n + 1 << ": expected ;\n";
				fi.close();
				fo.close();
				hex_out.close();
				return -1;
			}
			line.erase(pos + 1, line.length() - pos - 1);
			
			/* To Uppercase */
			std::transform(line.begin(), line.end(), line.begin(), toupper);
			std::cout << "Line: " << line << "\n";
				
			/* Parsing */
			pos = line.find_first_of(" \t;");
			instr = line.substr(0, pos); // Reads instruction
			std::cout << "Instruction is: " << instr << "*\n";
			
		
			if (line[pos] != ';') {
				
				// aux substring is line without instruction and ;
				aux = line.substr(pos, line.length() - pos - 1);
				pos = aux.find_first_not_of(whitespaces);
				if (aux[pos] != ';') {
					
					// Trimming whitespace before data
					nnn = aux.substr(pos);
					VX = aux.substr(pos);

					/* Find nnn */
					
					// Erase whitespace after data	
					pos = nnn.find_first_of(whitespaces); 
					if (pos != std::string::npos) {
						nnn.erase(pos);
					}


					/* Find VX, VY and nibble */
					
					// Search for , separator
					pos = VX.find_first_of(",");
					if (pos != std::string::npos) {
						// Found: copies everything after , to VY
						// and erases it from VX
						VY = VX.substr(pos + 1);
						VX.erase(pos);
						
						// Trimming left of VY
						pos = VY.find_first_not_of(whitespaces);
						VY.erase(0, pos);
						
						// Search for second , separator
						pos = VY.find_first_of(",");
						if (pos != std::string::npos) {
							// Found: copies everything after , to nibble
							// and erases it from VY		
							nibble = VY.substr(pos + 1);
							VY.erase(pos);

							// Trimming nibble
							pos = nibble.find_first_not_of(whitespaces);
							nibble.erase(0, pos);
							pos = nibble.find_first_of(whitespaces);
							if (pos != std::string::npos) {
								nibble.erase(pos);
							}

							// Trimming right of VY
							pos = VY.find_first_of(whitespaces);
							if (pos != std::string::npos) {
								VY.erase(pos);
							}

						} else {
							// Not found: erase whitespace after VY
							// nibble does not exist
							
							pos = VY.find_first_of(whitespaces);
							if (pos != std::string::npos) {
								VY.erase(pos);
							}

							nibble = "";
						}
					} else {
						// Not found: erase whitespace after VX
						
						pos = VX.find_first_of(whitespaces);
						if (pos != std::string::npos) {
							VX.erase(pos);
						}
						VY = "";
						nibble = "";
					}
					byte = VY;
				}
			}	
			std::cout << "Address is: " << nnn << "*\n";
			std::cout << "VX is: " << VX << "*\n";
			std::cout << "VY is: " << VY << "*\n";
			std::cout << "Nibble is: " << nibble << "*\n";
			std::cout << "Byte is: " << byte << "*\n";	
			
			
			std::cout << "Map value is: " << opcodeMap[instr] << std::endl;
			
			// Interpreting instruction
			switch(opcodeMap[instr]) {
				case CLS: op = "00E0"; break;
				case RET: op = "00EE"; break;
				case JP:
					CHECKNNN(nnn);
					op = "1" + nnn;
					break;
				case CALL:
					CHECKNNN(nnn);
					op = "2" + nnn;
					break;
				case SE:
					CHECKV(VX);
					CHECKBYTE(byte);
					op = "3" + VX + byte;
					break;
				case SNE:
					CHECKV(VX);
					CHECKBYTE(byte);
					op = "4" + VX + byte;
					break;
				case SER:
					CHECKV(VX);
					CHECKV(VY);
					op = "5" + VX + VY + "0";
					break;
				case LD:
					CHECKV(VX);
					CHECKBYTE(byte);
					op = "6" + VX + byte;
					break;
				case ADD:
					CHECKV(VX);
					CHECKBYTE(byte);
					op = "7" + VX + byte;
					break;
				case LDR:
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "0";
					break;
				case OR:	
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "1";
					break;
				case AND:	
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "2";
					break;
				case XOR:	
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "3";
					break;
				case ADDR:	
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "4";
					break;
				case SUBR:	
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "5";
					break;
				case SHR:
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "6";
					break;
				case SUBNR:
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "7";
					break;
				case SHL:
					CHECKV(VX);
					CHECKV(VY);
					op = "8" + VX + VY + "E";
					break;
				case SNER:
					CHECKV(VX);
					CHECKV(VY);
					op = "9" + VX + VY + "0";
					break;
				case LDI:
					CHECKNNN(nnn);
					op = "A" + nnn;
					break;
				case JPV0:
					CHECKNNN(nnn);
					op = "B" + nnn;
					break;
				case RND:
					CHECKV(VX);
					CHECKBYTE(byte);
					op = "C" + VX + byte;
					break;
				case DRW:
					CHECKV(VX);
					CHECKV(VY);
					CHECKNIBBLE(nibble);
					op = "D" + VX + VY + nibble;
					break;
				case SKP:
					CHECKV(VX);
					op = "E" + VX + "9E";
					break;
				case SKNP:
					CHECKV(VX);
					op = "E" + VX + "A1";
					break;
				case LDXDT:	
					CHECKV(VX);
					op = "F" + VX + "07";
					break;
				case LDK:	
					CHECKV(VX);
					op = "F" + VX + "0A";
					break;
				case LDDTX:	
					CHECKV(VX);
					op = "F" + VX + "15";
					break;
				case LDSTX:	
					CHECKV(VX);
					op = "F" + VX + "18";
					break;
				case ADDI:
					CHECKV(VX);
					op = "F" + VX + "1E";
					break;
				case LDLOC:
					CHECKV(VX);
					op = "F" + VX + "29";
					break;
				case LDBCD:
					CHECKV(VX);
					op = "F" + VX + "33";
					break;
				case LDMR:
					CHECKV(VX);
					op = "F" + VX + "55";
					break;
				case LDRM:
					CHECKV(VX);
					op = "F" + VX + "65";
					break;
				default:
					std::cout << "Line " << n + 1 << ": unknown instruction " << instr << ";\n";

			}
			std::cout << "Opcode is: " << op << "\n\n";
			
			fo << hex(  2*n  ) + " : " + op[0] + op[1] + ";\n";
			fo << hex(2*n + 1) + " : " + op[2] + op[3] + ";\n";
			hex_out << op[0]; 
			hex_out << op[1];
		       	hex_out << "\n";
		       	hex_out << op[2];
		       	hex_out << op[3];
		       	hex_out << "\n";
			n++;
		}
		fo << "[" << hex(2*n) << ".." << hex(4095) << "] : 00;\n";
		fo << "END;";
	}

	fi.close();
	fo.close();
	return 0;
}

void mapInit() {
	opcodeMap["CLS"] = CLS;
	opcodeMap["RET"] = RET;
	opcodeMap["JP"] = JP;
	opcodeMap["CALL"] = CALL;
	opcodeMap["SE"] = SE;
	opcodeMap["SNE"] = SNE;
	opcodeMap["SER"] = SER;
	opcodeMap["LD"] = LD;
	opcodeMap["ADD"] = ADD;
	opcodeMap["LDR"] = LDR;
	opcodeMap["OR"] = OR;
	opcodeMap["AND"] = AND;
	opcodeMap["XOR"] = XOR;
	opcodeMap["ADDR"] = ADDR;
	opcodeMap["SUBR"] = SUBR;
	opcodeMap["SHR"] = SHR;
	opcodeMap["SUBNR"] = SUBNR;
	opcodeMap["SHL"] = SHL;
	opcodeMap["SNER"] = SNER;
	opcodeMap["LDI"] = LDI;
	opcodeMap["JPV0"] = JPV0;
	opcodeMap["RND"] = RND;
	opcodeMap["DRW"] = DRW;
	opcodeMap["SKP"] = SKP;
	opcodeMap["SKNP"] = SKNP;
	opcodeMap["LDXDT"] = LDXDT;
	opcodeMap["LDK"] = LDK;
	opcodeMap["LDDTX"] = LDDTX;
	opcodeMap["LDSTX"] = LDSTX;
	opcodeMap["ADDI"] = ADDI;
	opcodeMap["LDLOC"] = LDLOC;
	opcodeMap["LDBCD"] = LDBCD;
	opcodeMap["LDMR"] = LDMR;
	opcodeMap["LDRM"] = LDRM;
}

unsigned dec(std::string hex) {
	unsigned out;
	std::stringstream ss;
	ss << std::dec << hex;
	ss >> out;
	return out;
}

std::string hex(unsigned dec) {
	unsigned aux;
	unsigned digits[4];
	std::stringstream ss;
	
	digits[0] = dec / (16 * 16 * 16);
	aux = dec % (16 * 16 * 16);
	digits[1] = aux / (16 * 16);
	aux = aux % (16 * 16);
	digits[2] = aux / 16;
	digits[3] = aux % 16;
	
	for (int i = 0; i < 4; i++) {
		switch(digits[i]) {
			case 10: ss << "A"; break;
			case 11: ss << "B"; break;
			case 12: ss << "C"; break;
			case 13: ss << "D"; break;
			case 14: ss << "E"; break;
			case 15: ss << "F"; break;
			default: ss << digits[i];
		}
	}
	return ss.str();
}


void checknnn(std::string nnn) {
	
}
