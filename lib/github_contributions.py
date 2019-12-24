import json
import os

from dotenv import load_dotenv
from github import Github

load_dotenv()


USERNAME = 'BigChief45'
OUTPUT_PATH = os.path.join(os.path.dirname(__file__), '../data/open_source.json')

REPOSITORIES = [
  'rails/rails',
  'aws/chalice',
  'aws/aws-sdk-java',
  'serverless/serverless',
  'encode/httpx',
  'ajaxorg/ace',
  'timgrossmann/InstaPy',
  'jneen/rouge',
  'gnocchixyz/gnocchi',
  # 'gnocchixyz/python-gnocchiclient',
  # 'ElemeFE/element',
  # 'iview/iview-doc',
  'openstack-dev/pbr',
  # 'GetStream/Winds',
]


client = Github(os.environ['GITHUB_TOKEN'])


class Repository:

    def __init__(self, url):
        self._repository = client.get_repo(url)
        self.url = url
        self.description = self._repository.description

        self._stats = self._repository.get_stats_contributors()

    def _get_stats_for_user(self, username: str):
        # Stats for a repository will be empty if not enough contributions
        # have been made.

        user_stats = None
        for stat in self._stats:
            if stat.author.login == username:
                user_stats = stat
                break

        return user_stats

    def get_user_commits(self, username: str) -> int:
        return self._repository.get_commits(author=username).totalCount

    def get_user_additions(self, username: str) -> int:
        user_stats = self._get_stats_for_user(username)
        if user_stats is None:
            return None

        return sum([week.a for week in user_stats.weeks])

    def get_user_deletions(self, username: str) -> int:
        user_stats = self._get_stats_for_user(username)
        if user_stats is None:
            return None

        return sum([week.d for week in user_stats.weeks])

    def get_user_contributions(self, username: str):
        print(f'Getting contributions for repository {self.url}')

        return {
            'url': self.url,
            'description': self._repository.description,
            'commits': self.get_user_commits(username),
            'additions': self.get_user_additions(username),
            'deletions': self.get_user_deletions(username),
            'image': self.url.split('/')[-1]
        }


if __name__ == '__main__':
    contributions = [
        Repository(repo_url).get_user_contributions(USERNAME) for repo_url in REPOSITORIES
    ]

    with open(OUTPUT_PATH, 'w') as output_file:
        print(f'Saving contributions data to {OUTPUT_PATH}')
        output_file.write(json.dumps(contributions))
