import json
import matlab.engine


def format_num(num: int) -> str:
    dif = 3 - len(str(num))
    return "0"*dif + str(num)


def link_gen(X: int, Y: int, Z: int, mode: str, cycle_num: int) -> str:
    LINK = "docs\\21.10.22_Holo_exp\\"
    if mode == "focus":
        LINK += f"\\OnHydrFocus5V\OnHydr{cycle_num}cyc.txt"
    elif mode == "transducer":
        LINK += f"\\OnHydrFocus5V\OnHydr{cycle_num}cyc.txt"
    else:
        LINK += f"ScanX{format_num(X)}Y{format_num(Y)}.txt"
    return LINK


def main():
    # get default params
    link_dict = json.load(open("report_params.json"))["link"]
    X = link_dict["X"]
    Y = link_dict["Y"]
    Z = link_dict["Z"]
    mode = link_dict["mode"]
    cycle_num = link_dict["cycle_num"]

    # calc each point
    for i in range(cycle_num):
        LINK = link_gen(X=X, Y=Y, Z=Z, mode=mode, cycle_num=cycle_num)
        eng = matlab.engine.start_matlab()
        eng.profile_experiment(LINK)


if __name__ == '__main__':
    main()
