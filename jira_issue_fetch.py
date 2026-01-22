from jira import JIRA
import requests

def get_requirements(jira_url, username, api_token, jql_query, max_results=50):
    """
    Connects to Jira and fetches issues based on JQL query.
    Returns enriched issue data including key, summary, description,
    status, priority, issue type, and attachments.
    """
    result = {"status": False, "issues": [], "message": ""}
    try {
        # Connect to Jira
        jira_client = JIRA(server=jira_url, basic_auth=(username, api_token))

        # Fetch issues
        issues = jira_client.search_issues(jql_query, maxResults=max_results)

        enriched_issues = []
        for issue in issues:
            issue_type = issue.fields.issuetype
            priority = issue.fields.priority
            status = issue.fields.status
            issue_type_description = issue_type.description if issue_type else None

            issue_data = {
                "key": issue.key,
                "summary": issue.fields.summary,
                "description": issue.fields.description or "",
                "status": status.name if status else None,
                "priority": priority.name if priority else None,
                "issue_type": issue_type.name if issue_type else None,
                "attachments": []
            }

            # Process attachments
            if hasattr(issue.fields, 'attachment') and issue.fields.attachment:
                for attachment in issue.fields.attachment:
                    file_url = attachment.content
                    file_name = attachment.filename

                    response = requests.get(file_url, auth=(username, api_token))
                    if response.status_code == 200:
                        file_content = (
                            response.content.decode(errors="ignore")
                            if attachment.mimeType.startswith("text")
                            else None
                        )
                        issue_data["attachments"].append({
                            "filename": file_name,
                            "mimeType": attachment.mimeType,
                            "size": attachment.size,
                            "content": file_content
                        })
                    else {
                        issue_data["attachments"].append({
                            "filename": file_name,
                            "mimeType": attachment.mimeType,
                            "size": attachment.size,
                            "content": None
                        })
                    }

            enriched_issues.append(issue_data)

        result["status"] = True
        result["issues"] = enriched_issues
        result["message"] = f"Retrieved {len(issues)} issues successfully."

    } except Exception as e {
        result["message"] = f"Error retrieving issues: {str(e)}"
    }

    return result
