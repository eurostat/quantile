#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
.. flask_quantile

**Description**

Run a micro web-service that runs the calculation of empirical quantiles. 
   
**Usage**
"""

"""
**About**

This code is intended as a proof of concept for the following publication:
* Grazzini J. and Lamarche P. (2017): Production of social statistics... goes social!, 
    in Proc. New Techniques and Technologies for Statistics.

Copyright (c) 2017, J.Grazzini & P.Lamarche, European Commission
Licensed under [European Union Public License](https://joinup.ec.europa.eu/community/eupl/og_page/european-union-public-licence-eupl-v11)
"""

import os
import sys

# cheating, since we do not adopt a real app project... 
# just for testing purpose so as to be able to import the quantile modules
sys.path.insert(0, os.path.abspath(os.path.join(os.getcwd(),'../src/')))

import quantile 
import io_quantile 

from flask import Flask, request, redirect, url_for, \
     render_template, flash, send_from_directory
from flask_wtf import FlaskForm, file
from flask_wtf.file import FileField, FileAllowed, FileRequired
from wtforms import Form, validators
from wtforms import BooleanField, TextField, StringField, FloatField, RadioField, \
    SelectField, SubmitField, FieldList
# from werkzeug import secure_filename

UPLOAD_FOLDER       = 'uploads/'
ALLOWED_EXTENSIONS  = ['txt', 'csv']
SECRET_KEY          = 'no secret key'
SESSION_TYPE        = 'filesystem' 

class OptionalIfFieldEqualTo(validators.Optional):
    # a validator which makes a field optional if
    # another field has a desired value

    def __init__(self, other_field_name, value, *args, **kwargs):
        self.other_field_name = other_field_name
        self.value = value
        super(OptionalIfFieldEqualTo, self).__init__(*args, **kwargs)

    def __call__(self, form, field):
        other_field = form._fields.get(self.other_field_name)
        if other_field is None:
            raise Exception('no field named "%s" in form' % self.other_field_name)
        if other_field.data == self.value:
            super(OptionalIfFieldEqualTo, self).__call__(form, field)

# Model
class QuantileForm(FlaskForm):
    
    def __init__(self, *args, **kwargs):
        # see http://stackoverflow.com/questions/18716920/flask-wtforms-always-give-false-on-validate-on-submit
        kwargs['csrf_enabled'] = False
        super(QuantileForm, self).__init__(*args, **kwargs)
    
    data = FileField(u'Data file',                                              \
                     validators=[validators.Required('!!! Select the path to CSV file with sample data !!!')]) # validators.regexp(u'^[^/\\]\.csv$')
    typ = SelectField(u'Algorithm selection', coerce=int, \
                      choices=quantile.ALGORITHMS,      \
                      default=quantile.ALGORITHMS[6])
    squant = SelectField(u'Quantile probablities selection', #coerce=int,           \
                          choices=quantile.SQUANTILES,                  \
                          default=quantile.SQUANTILES[3])
    #fmtprobs = RadioField('Quantile probabilities entered as: ',                \
    #                      choices = [('F','a csv file'),('L','a list')])
    #probs = FileField(u'Quantile probabilities',                                \
    #    validators=[OptionalIfFieldEqualTo('fmtprobs','F')]) # [validators.regexp(u'^[^/\\]\.csv$')]
    method = SelectField(u'method', choices=quantile.APPROACHES)
    # limit= FloatField(u'Limits of sampled data', [validators.NumberRange(min=0, max=1.)])
    na_rm = BooleanField(
        label=u'Remove NA and NaN from input dataset?', default=False)
    submit = SubmitField(u'COMPUTE')
    
# View
def allowed_file(filename):
    """Does filename have the right extension?
    """
    return '.' in filename and \
        filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS
    
def check_folder(folder):
    """Create upload folder when it does not exist
    """
    if not os.path.isdir(folder):
        os.mkdir(folder)
        
app = Flask(__name__)

# This is the path to the upload directory
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
 
# These are the extension that we are accepting to be uploaded
app.config['ALLOWED_EXTENSIONS'] = set(ALLOWED_EXTENSIONS)


@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':        
        form = QuantileForm() #(request.form) #(csrf_enabled=False) #deprecated
        if form.validate_on_submit() == False:
            flash('Missing fields')
            return render_template('index.html', form=form, result=None)
        # check if the post request has the file part
        if 'data' not in request.files: # anyway, the form would not have been validated
            flash('No file uploaded')
            return redirect(url_for('index'))
        datafile = request.files['data']
        # check if the file is one of the allowed types/extensions
        filename = datafile.filename
        if filename == '' or not allowed_file(filename): 
            flash('File not recognised')
            return redirect(url_for('index'))
        # Move the file form the temporal folder to
        # the upload folder we setup
        path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        datafile.save(path)
        #return redirect(url_for('uploaded_file',
        #                        filename=filename))
        ioQ = io_quantile.IO_Quantile(probs=form.squant.data, typ=form.typ.data,
            method=form.method.data, na_rm=form.na_rm.data
            ) 
        result = ioQ(path)
        # print(result, file=sys.stderr)
    else:
        form = QuantileForm(formdata=None)
        result = None
    
    return render_template('index.html', form=form, result=result)#return redirect(url_for('index'))

        
@app.route('/uploads/<filename>')
def uploaded_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

if __name__ == '__main__':
    app.secret_key = SECRET_KEY
    app.config['SESSION_TYPE'] = SESSION_TYPE    
 
    # to kill the session (running on http://127.0.0.1:5000):
    # find the PID for port=5000: lsof -i :5000 
    # kill it: sudo kill -9 PID 
    app.run(
        debug=True
    )
