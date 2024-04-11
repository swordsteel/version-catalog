import java.lang.System.getenv

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

        fun retrieveConfiguration(
            property: String,
            environment: String,
        ): String? = project.findProperty(property)?.toString() ?: getenv(environment)

        // TODO configuration for publishing packages
        // maven {
        //     name = "LuLz-Ltd"
        //     url = uri("https://")
        //     credentials(HttpHeaderCredentials::class) {
        //         username = retrieveConfiguration("repositoryUser", "REPOSITORY_USER")
        //         password = retrieveConfiguration("repositoryToken", "REPOSITORY_TOKEN")
        //     }
        //     authentication {
        //         create("header", HttpHeaderAuthentication::class)
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
