from flask import Flask, render_template, request, redirect, url_for
import numpy as np
import mmap
import os
import time


html_doc='''<!DOCTYPE html>
<html lang="ja">
<head><title>LED sample</title></head>
<body>
<form action="/post" method="post" class="form-inline">
<label for="led">LED:</label>
<input type="checkbox" class="form-control" id="led" name="led" value="LED" %s>
<button type="submit" class="btn btn-default">send</button>
</form>
</body>
</html>'''


# uio mmap
uio_name = '/dev/uio4'
uio_file = os.open(uio_name, os.O_RDWR | os.O_SYNC)
uio_mmap = mmap.mmap(uio_file, 0x100000, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE, offset=0)
mem_array = np.frombuffer(uio_mmap, np.uint64, 1, 0x8000)

app = Flask(__name__)

@app.route('/')
def index():
    return html_doc % ""

@app.route('/post', methods=['GET', 'POST'])
def post():
    if request.method == 'POST':
        if 'led' in request.form:
            led = request.form['led']
            print('LED:ON')
            mem_array[0] = 1
            return html_doc % "checked"
        else:
            print('LED:OFF')
            mem_array[0] = 0
            return html_doc % ""
    else:
        return html_doc % ""

if __name__ == '__main__':
    app.debug = True
    app.run(host='0.0.0.0')
