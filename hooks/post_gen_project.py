from git import Repo
import glob

try:
    repo = Repo()
    repo.index.add("*")

except:
    files = glob.glob("*", include_hidden=True)
    repo = Repo.init()
    repo.index.add(files)
    repo.index.commit('Initial commit')
