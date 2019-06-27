package com.zzw.rendertoyandroid;

import android.content.Context;
import android.opengl.GLES20;
import android.opengl.GLSurfaceView;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import com.zzw.rendertoyandroid.render.ShaderToy;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * Created by zzw on 2019-06-27
 * Des:
 */
public class MyGLRender implements GLSurfaceView.Renderer, View.OnTouchListener {

    private Context context;

    private ShaderToy shaderToy;

    public MyGLRender(Context context) {
        this.context = context;
    }

    @Override
    public void onSurfaceCreated(GL10 gl, EGLConfig config) {
        shaderToy = new ShaderToy(context);
        shaderToy.onSurfaceCreated();
    }

    @Override
    public void onSurfaceChanged(GL10 gl, int width, int height) {
        shaderToy.onSurfaceChanged(width, height);
    }

    @Override
    public void onDrawFrame(GL10 gl) {
        shaderToy.draw();
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        return shaderToy != null && shaderToy.onTouch(v, event);
    }
}
