// Auto-generated
package ;
class Main {
    public static inline var projectName = 'SteelSoul';
    public static inline var projectVersion = '1.0.2';
    public static inline var projectPackage = 'arm';
    public static function main() {
        iron.object.BoneAnimation.skinMaxBones = 33;
        armory.system.Starter.main(
            'GameScene',
            0,
            false,
            true,
            false,
            1920,
            1080,
            1,
            true,
            armory.renderpath.RenderPathCreator.get
        );
    }
}
