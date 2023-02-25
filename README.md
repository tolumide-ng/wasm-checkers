Reference table when working with bit masked or "packed" values:

| Logical Operation | WebAssembly | Bitmask Action |
| ----------------- | ----------- | -------------- |
| AND               | i32.and     | Query the value of a bit |
| OR                | i32.or      | Sets a bit to true (1)  |
| XOR               | i32.xor     | Toggles the value of a bit  |


#### Assigning meaning to the bits of an integer on a checkerboard:
| Binary Value                   | Decimal Value      | Game Meaning             |
| ------------------------------ | ------------------ | ------------------------ |
| [unused 24 bits]...00000000    | 0                  | UnOccupied Square        |
| [unused 24 bits]...00000001    | 1                  | Black Piece              |
| [unused 24 bits]...00000010    | 2                  | White Piece              |
| [unused 24 bits]...00000100    | 4                  | Crowned Piece            |


#### Truth table illustrating how the game works
| Value | Meaning | Operation | Mask | Result |
| ----- | ------- | --------- | ---- | ------ |
| 0101  | Crowned Black | & | 0011 | 0001 (B) |
| 0001  | UnCrowned Black | & | 0011 | 0001 (B) |
| 0110  | Crowned White | & | 0011  | 0010 (W)  |



### How to Run this project
1. You can simply serve this application with python3 using the command below:
```
python3 -m http.server
```
2. Open the web console to view the updates

#### NB:
- In order to make changes to the `checkers.wat` file or to recompile it
- Simply Clone the [wabt](https://github.com/WebAssembly/wabt), setup wabt(using the README.md file there), and copy this project into the root directory of wabt(Web Asssembly Toolkit)



### Based On:
- [Programming WebAssembly (Unified Development for Web, Mobile, and Embedded Applications) with Rust by Kevin Hoffman](https://pragprog.com/titles/khrust/programming-webassembly-with-rust/)