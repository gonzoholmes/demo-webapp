import os

from flask import Flask, render_template, request
from pymongo import MongoClient

app = Flask(__name__)

mongo_uri = os.environ["MONGO_URI"]
client = MongoClient(mongo_uri)
db = client.get_default_database()
starsigns = db.starsigns

ZODIAC = [
    ((1, 20), (2, 18), "Aquarius", "\U0001F778"),
    ((2, 19), (3, 20), "Pisces", "\U00002653"),
    ((3, 21), (4, 19), "Aries", "\U00002648"),
    ((4, 20), (5, 20), "Taurus", "\U00002649"),
    ((5, 21), (6, 20), "Gemini", "\U0000264A"),
    ((6, 21), (7, 22), "Cancer", "\U0000264B"),
    ((7, 23), (8, 22), "Leo", "\U0000264C"),
    ((8, 23), (9, 22), "Virgo", "\U0000264D"),
    ((9, 23), (10, 22), "Libra", "\U0000264E"),
    ((10, 23), (11, 21), "Scorpio", "\U0000264F"),
    ((11, 22), (12, 21), "Sagittarius", "\U00002650"),
]
CAPRICORN = ("Capricorn", "\U00002651")


def zodiac_sign(month: int, day: int) -> tuple[str, str]:
    for (start_m, start_d), (end_m, end_d), name, emoji in ZODIAC:
        if (month == start_m and day >= start_d) or (month == end_m and day <= end_d):
            return name, emoji
    return CAPRICORN


@app.route("/", methods=["GET", "POST"])
def index():
    result = None
    if request.method == "POST":
        name = request.form["name"].strip()
        month = int(request.form["month"])
        day = int(request.form["day"])

        sign, emoji = zodiac_sign(month, day)

        starsigns.insert_one({"name": name, "day": day, "month": month, "sign": sign})
        count = starsigns.count_documents({"sign": sign})

        result = {"name": name, "sign": sign, "emoji": emoji, "count": count}

    return render_template("index.html", result=result)


@app.route("/healthz")
def healthz():
    client.admin.command("ping")
    return {"status": "ok"}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
