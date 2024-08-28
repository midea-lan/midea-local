import { RuleConfigSeverity } from "@commitlint/types";

const Configuration = {
  /*
   * Resolve and load @commitlint/config-conventional from node_modules.
   * Referenced packages must be installed
   */
  extends: ["@commitlint/config-conventional"],
  /*
   * Any rules defined here will override rules from @commitlint/config-conventional
   */
  rules: {
    "body-max-line-length": [RuleConfigSeverity.Error, "always", 300],
  },
};

export default Configuration;
