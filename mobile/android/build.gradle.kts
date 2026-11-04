allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// keyboard_height_plugin 0.1.5 (pulled in by the vendored appflowy_editor) still compiles against Android 31, which
// today's AndroidX AAR metadata check rejects: build it against a current SDK. Registered before `:app` is evaluated
// so it runs before AGP finalizes the plugin's DSL.
subprojects {
    if (name == "keyboard_height_plugin") {
        afterEvaluate {
            extensions.getByName("android").withGroovyBuilder { "setCompileSdk"(36) }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
