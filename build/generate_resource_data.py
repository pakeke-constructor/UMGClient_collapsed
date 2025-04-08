import sys

def main():
    major, minor, patch = map(int, sys.argv[1].split("."))
    with open(sys.argv[2], "r", encoding="utf-8", newline="") as f:
        with open(sys.argv[3], "w", encoding="utf-8", newline="\r\n") as f2:
            f2.write(f.read() % {"major": major, "minor": minor, "patch": patch})

if __name__ == "__main__":
    main()
