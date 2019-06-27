package com.zzw.rendertoyandroid;

import android.content.Context;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;

/**
 * Created by zzw on 2019-06-27
 * Des:
 */
public class MySurfaceView extends GLSurfaceView {
    public MySurfaceView(Context context) {
        this(context, null);
    }

    public MySurfaceView(Context context, AttributeSet attrs) {
        super(context, attrs);
        setEGLContextClientVersion(2);
        MyGLRender render = new MyGLRender(context);
        setRenderer(render);
        setRenderMode(GLSurfaceView.RENDERMODE_CONTINUOUSLY);
        setOnTouchListener(render);
    }
}
