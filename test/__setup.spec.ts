// import { revertToSnapshot, takeSnapshot } from "../tasks/helpers/utils";

// export function makeSuiteCleanRoom(name: string, tests: () => void) {
//     describe(name, () => {
//       beforeEach(async function () {
//           await takeSnapshot();

//       });
//       tests();
//       afterEach(async function () {
//           await revertToSnapshot();

//       });
//     });
//   }
