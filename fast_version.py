import sys
from get_latest_fast_version import get_latest_version

if __name__ == '__main__':
    input = sys.argv[1]
    if input == 'latest':
        print(get_latest_version())
    else:
        # Validate version
        parts = input.split('.')
        if len(parts) != 3:
            raise ValueError('FAST version incorrect:', input)
        for i in range(3):
            try:
                if str(int(parts[i])) != parts[i]:
                    raise ValueError('Not integer')
            except:
                raise ValueError('FAST version incorrect:', input)

        print(input)
