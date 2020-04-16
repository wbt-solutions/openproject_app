import 'package:openproject_dart_sdk/api.dart';

class ProjectTree {
  Projects projects;
  ProjectNode rootNode = ProjectNode(null);

  ProjectTree(this.projects) {
    _buildTree(rootNode);
  }

  void _buildTree(ProjectNode node) {
    for (Project project in projects.embedded.elements) {
      if (node.project == null) {
        if (project.links.parent.href == null) {
          _buildNode(node, project);
        }
      } else {
        if (project.links.parent.href == node.project.links.self.href) {
          _buildNode(node, project);
        }
      }
    }
  }

  void _buildNode(ProjectNode rootNode, Project project) {
    ProjectNode projectNode = ProjectNode(project);
    _buildTree(projectNode);
    rootNode.children.add(projectNode);
  }
}

class ProjectNode {
  Project project;
  List<ProjectNode> children = [];
  bool isExpanded = false;

  ProjectNode(this.project);
}
