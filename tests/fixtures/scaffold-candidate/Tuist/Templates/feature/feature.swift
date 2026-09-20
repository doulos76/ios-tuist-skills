import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "Generates a single Swift source file declaring a "
        + "public enum named <name>Label with a static text property.",
    attributes: [
        nameAttribute
    ],
    items: [
        .file(
            path: "Sources/\(nameAttribute)Label.swift",
            templatePath: "source.stencil"
        )
    ]
)
