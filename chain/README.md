# Chain

chain folder contains the CUE libraries to compose into advanced stacks like gin-next.

## Why called chain

chain means that each module has input and output and processor. Each module are chained together.

## Directory layout

Under chain/, it contains:

- **factory**:
		The factory modules that creates instances (e.g. scaffold) from specified option (e.g. gin-next).
- **components**:
		The component modules that are processing given input and generates output. Some modules might have side effects.
- **internal**:
		This is the internal modules that users should not use.
- cue.mod/, cue.mods:
		This is the CUE mod definition of the entire chain/ module.
