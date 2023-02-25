fetch("../checkers.wasm").then(response => response.arrayBuffer())
    .then(bytes => WebAssembly.instantiate(bytes, {
        events: {
            piecemoved: (fx, fy, tx, ty) => {
                console.log(`A piece moved from (${fx},${fy}) to (${tx},${ty})`)
            },
            piececrowned: (x, y) => {
                console.log(`A piece was crowned at (${x},${y})`);
            },
        }
    })).then(results => {
        const {instance: {exports}} = results;
        exports.initBoard();
        console.log(`At start, turn owner is ${exports.getTurnOwner()}`);

        exports.move(0, 5, 0, 4); // B
        exports.move(1, 0, 1, 1); // W
        exports.move(0, 4, 0, 3); // B
        exports.move(1, 1, 1, 0); // W
        exports.move(0, 3, 0, 2); // B
        exports.move(1, 0, 1, 1); // W
        exports.move(0, 2, 0, 0); // B - this will get a crown
        exports.move(1, 1, 1, 0); // W
        const res = exports.move(0, 0, 0, 2); // B - move the crowned piece out

        document.getElementById("container").innerText = res;
        console.log("At end, turn owner is " + exports.getTurnOwner());
    }).catch(console.error)