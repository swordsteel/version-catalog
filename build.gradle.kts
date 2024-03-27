plugins {
    `version-catalog`
    `maven-publish`
}

description = "Lulz Ltd Test Version Catalog"
group = "ltd.lulz.catalog"

catalog {
    versionCatalog {
        from(files("lulz.versions.toml"))
    }
}

publishing {
    repositories {
        // TODO configuration for publishing packages
        // maven {
        //     url = uri("https://")
        //     credentials {
        //         username =
        //         password =
        //     }
        // }
    }
    publications {
        create<MavenPublication>("version-catalog") {
            groupId = "$group"
            artifactId = project.name
            version = version
            from(components["versionCatalog"])
        }
    }
}
tasks.register("clean") {
    group = "build"
    doLast {
        delete("${rootDir.path}/build")
        println("Default Cleaning!")
    }
}
