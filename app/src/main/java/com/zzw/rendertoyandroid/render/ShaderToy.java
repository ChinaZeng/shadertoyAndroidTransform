package com.zzw.rendertoyandroid.render;

import android.content.Context;
import android.opengl.GLES20;
import android.os.SystemClock;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;
import com.zzw.rendertoyandroid.R;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/**
 * Created by zzw on 2019-06-27
 * Des:
 */
public class ShaderToy implements View.OnTouchListener {
    private Context context;

    //顶点坐标
    static float vertexData[] = {   // in counterclockwise order:
            -1f, -1f, 0.0f, // bottom left
            1f, -1f, 0.0f, // bottom right
            -1f, 1f, 0.0f, // top left
            1f, 1f, 0.0f,  // top right
    };
    //纹理坐标
    static float textureData[] = {   // in counterclockwise order:
            0f, 1f, 0.0f, // bottom left
            1f, 1f, 0.0f, // bottom right
            0f, 0f, 0.0f, // top left
            1f, 0f, 0.0f,  // top right
    };
    //每一次取点的时候取几个点
    private static final int COORDS_PER_VERTEX = 3;

    private final int vertexCount = vertexData.length / COORDS_PER_VERTEX;
    //每一次取的总的点 大小
    private final int vertexStride = COORDS_PER_VERTEX * 4; // 4 bytes per vertex

    //位置
    private FloatBuffer vertexBuffer;
    //纹理
    private FloatBuffer textureBuffer;

    private int program;

    //顶点位置
    private int mavPosition;
    //纹理位置
    private int mafPosition;
    //全局时间句柄
    private int miTimeHandle;
    //宽高
    private int miResolutionHandle;
    //点击位置
    private int miMouseHandle;


    private float[] mMouse = new float[]{0, 0, 0, 0};
    private float[] mResolution;
    private long mStartTime;


    public ShaderToy(Context context) {
        this.context = context;

        vertexBuffer = ByteBuffer.allocateDirect(vertexData.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer()
                .put(vertexData);
        vertexBuffer.position(0);

        textureBuffer = ByteBuffer.allocateDirect(textureData.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer()
                .put(textureData);
        textureBuffer.position(0);
    }


    public void onSurfaceCreated() {
        String vertexSource = ShaderUtil.readRawTxt(context, R.raw.vertex_shader);
        String fragmentSource = ShaderUtil.readRawTxt(context, R.raw.fragment_shader);
        program = ShaderUtil.createProgram(vertexSource, fragmentSource);
        if (program > 0) {
            //获取顶点坐标字段
            mavPosition = GLES20.glGetAttribLocation(program, "av_Position");
            //获取纹理坐标字段
            mafPosition = GLES20.glGetAttribLocation(program, "af_Position");
            //从运行的时候的时间
            miTimeHandle = GLES20.glGetUniformLocation(program, "iTime");
            //宽高
            miResolutionHandle = GLES20.glGetUniformLocation(program, "iResolution");
            //宽高
            miMouseHandle = GLES20.glGetUniformLocation(program, "iMouse");
        }
        mStartTime = SystemClock.elapsedRealtime();

    }

    public void draw() {
        //清空颜色
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT);
        //设置背景颜色
        GLES20.glClearColor(1.0f, 0.0f, 0.0f, 1.0f);

        //使用程序
        GLES20.glUseProgram(program);
        GLES20.glEnableVertexAttribArray(mavPosition);
        GLES20.glEnableVertexAttribArray(mafPosition);
        //设置顶点位置值
        GLES20.glVertexAttribPointer(mavPosition, COORDS_PER_VERTEX, GLES20.GL_FLOAT, false, vertexStride, vertexBuffer);
        //设置纹理位置值
        GLES20.glVertexAttribPointer(mafPosition, COORDS_PER_VERTEX, GLES20.GL_FLOAT, false, vertexStride, textureBuffer);

        GLES20.glUniform4fv(miMouseHandle, 1, mMouse, 0);
        GLES20.glUniform3fv(miResolutionHandle, 1, mResolution, 0);
        long nowInSec = SystemClock.elapsedRealtime();
        GLES20.glUniform1f(miTimeHandle, ((float) (nowInSec - mStartTime)) / 1000f);

//        GLES20.glActiveTexture(GLES20.GL_TEXTURE0);
//        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, miChannel0);
//        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_NEAREST);
//        GLES20.glTexParameteri(GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_NEAREST);

        //绘制 GLES20.GL_TRIANGLE_STRIP:复用坐标
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, vertexCount);

        GLES20.glDisableVertexAttribArray(mavPosition);
        GLES20.glDisableVertexAttribArray(mafPosition);
    }

    public void onSurfaceChanged(int width, int height) {
        mResolution = new float[]{width, height, 1f};
        //宽高
        GLES20.glViewport(0, 0, width, height);
    }

    @Override
    public boolean onTouch(View v, MotionEvent event) {
        if (event.getAction() == MotionEvent.ACTION_MOVE) {
            mMouse[0] = event.getX();
            mMouse[1] = event.getY();
        }
        return true;
    }
}
