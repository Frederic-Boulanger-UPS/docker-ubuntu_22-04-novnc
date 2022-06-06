#!/usr/bin/env python3

import tkinter as tk
from tkinter import messagebox
import sys
import os

root = tk.Tk()
root.withdraw()

#canvas1 = tk.Canvas(root, width = 300, height = 300)
#canvas1.pack()

def ExitApplication():
    MsgBox = tk.messagebox.askquestion ('Exit Session','Are you sure you want to exit the session?\nLocal data will be lost!',icon = 'warning')
    if MsgBox == 'yes':
        os.system("/usr/local/bin/killsession")
        tk.messagebox.showinfo('Exiting','Exiting session ...')
    else:
        tk.messagebox.showinfo('Cancelled','Exit session aborted')
    sys.exit(0)

#button1 = tk.Button (root, text='Exit Session', command=ExitApplication,bg='brown',fg='white')
#canvas1.create_window(150, 150, window=button1)

ExitApplication()

root.mainloop()
