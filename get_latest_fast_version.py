import requests

def get_latest_version():
    response = requests.get('https://api.github.com/repos/fast-imaging/fast/releases/latest')
    if response.status_code == 200:
        return response.json()['name'][1:]
    else:
        raise RuntimeError()

if __name__ == '__main__':
    print(get_latest_version())
