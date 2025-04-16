/**
 * This file is a minimal config to help Firebase buildpacks
 * understand that this is a static website deployment.
 * The actual content is served from the build/web directory
 * as specified in firebase.json.
 */
module.exports = {
  staticFiles: true
};
