package com.sisios.ashenarena;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.*;
import android.graphics.drawable.ColorDrawable;
import android.view.*;
import java.util.*;

public class GameActivity extends Activity {
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN, WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().getDecorView().setSystemUiVisibility(5894);
        setContentView(new ArenaView());
    }

    class ArenaView extends View {
        Paint p=new Paint(3); Paint stroke=new Paint(3); Random rng=new Random();
        boolean started=false,running=false,blocking=false,victory=false,defeat=false;
        float playerHp=260, playerMax=260, stamina=125, staminaMax=125;
        float bossHp=650,bossMax=650,bossTimer=2.2f,attackTimer=0,dodgeTimer=0,playerAttack=0;
        long last=System.nanoTime(); int boss=0, weapon=0, armor=0;
        String[] bossNames={"THE CINDER WARDEN","BELL-TOWER PENITENT","THE PALE HUNTRESS"};
        String[] bossTitles={"Keeper of the Last Pyre","The Chained Colossus","Daughter of the White Veil"};
        float[] bossHealth={650,920,560}, bossPower={19,29,23}, bossPace={1.0f,.7f,1.35f};
        int[] bossColors={Color.rgb(165,50,27),Color.rgb(85,94,101),Color.rgb(155,194,203)};
        String[] weapons={"IRON VOW BLADE","GRAVE GREATSWORD","PALE TWINBLADES","BELL HAMMER"};
        float[] weaponPower={31,47,27,53}, weaponCost={14,29,11,34};
        String[] armors={"WANDERER MAIL","CINDER PLATE","PENITENT IRON","WHITE VEIL GARB"};
        float[] armorReduction={.10f,.23f,.32f,.16f};
        RectF startButton=new RectF(), lightButton=new RectF(),heavyButton=new RectF(),dodgeButton=new RectF(),blockButton=new RectF(),gearButton=new RectF(),nextButton=new RectF();
        int activePointer=-1; float moveX=0,moveY=0;

        ArenaView(){ super(GameActivity.this); setBackground(new ColorDrawable(Color.BLACK)); p.setTypeface(Typeface.create("serif",Typeface.BOLD)); setFocusable(true); }

        void resetBoss(){
            playerHp=playerMax; stamina=staminaMax; bossMax=bossHealth[boss]; bossHp=bossMax;
            bossTimer=2.1f; attackTimer=playerAttack=dodgeTimer=0; victory=defeat=false; running=true;
        }

        @Override protected void onDraw(Canvas c){
            super.onDraw(c); float w=getWidth(),h=getHeight();
            long now=System.nanoTime(); float dt=Math.min(.035f,(now-last)/1_000_000_000f); last=now;
            if(started && running) update(dt);
            drawBackground(c,w,h);
            if(!started) drawStart(c,w,h); else drawBattle(c,w,h);
            postInvalidateOnAnimation();
        }

        void update(float dt){
            stamina=Math.min(staminaMax,stamina+dt*(blocking?7:22));
            if(dodgeTimer>0)dodgeTimer-=dt;
            if(playerAttack>0){
                float old=playerAttack; playerAttack-=dt;
                if(old>.16f && playerAttack<=.16f){
                    bossHp=Math.max(0,bossHp-weaponPower[weapon]);
                    if(bossHp<=0){victory=true;running=false;}
                }
            }
            bossTimer-=dt;
            if(attackTimer>0){
                float old=attackTimer; attackTimer-=dt;
                if(old>.12f&&attackTimer<=.12f&&dodgeTimer<=0){
                    float dmg=bossPower[boss]*(1-armorReduction[armor]);
                    if(blocking){dmg*=.24f;stamina=Math.max(0,stamina-dmg*1.6f);}
                    playerHp=Math.max(0,playerHp-dmg);
                    if(playerHp<=0){defeat=true;running=false;}
                }
            } else if(bossTimer<=0){
                attackTimer=boss==1?1.15f:boss==2?.55f:.82f;
                bossTimer=2.3f/bossPace[boss]+rng.nextFloat()*.6f;
            }
        }

        void drawBackground(Canvas c,float w,float h){
            p.setShader(new RadialGradient(w*.5f,h*.4f,Math.max(w,h)*.75f,new int[]{Color.rgb(55,35,30),Color.rgb(17,12,12),Color.BLACK},null,Shader.TileMode.CLAMP));
            c.drawRect(0,0,w,h,p);p.setShader(null);
            p.setColor(Color.rgb(35,23,20));c.drawOval(new RectF(w*.08f,h*.46f,w*.92f,h*.96f),p);
            stroke.setStyle(Paint.Style.STROKE);stroke.setStrokeWidth(2);stroke.setColor(Color.rgb(82,42,31));
            for(int i=0;i<16;i++){double a=i*Math.PI*2/16;c.drawLine(w*.5f,h*.7f,w*.5f+(float)Math.cos(a)*w*.42f,h*.7f+(float)Math.sin(a)*h*.22f,stroke);}
            stroke.setStyle(Paint.Style.FILL);
        }

        void drawStart(Canvas c,float w,float h){
            text(c,"♜",w/2,h*.28f,h*.18f,Color.rgb(224,91,42),Paint.Align.CENTER);
            text(c,"ASHEN ARENA",w/2,h*.48f,h*.09f,Color.rgb(235,219,196),Paint.Align.CENTER);
            text(c,"ΜΟΝΟΜΑΧΙΕΣ ΤΗΣ ΣΤΑΧΤΗΣ",w/2,h*.57f,h*.035f,Color.LTGRAY,Paint.Align.CENTER);
            startButton.set(w*.31f,h*.68f,w*.69f,h*.83f); button(c,startButton,"ΕΝΑΡΞΗ ΜΑΧΗΣ",false);
        }

        void drawBattle(Canvas c,float w,float h){
            text(c,bossNames[boss],w/2,h*.07f,h*.045f,Color.WHITE,Paint.Align.CENTER);
            bar(c,w*.18f,h*.09f,w*.82f,h*.12f,bossHp/bossMax,Color.rgb(201,56,31));
            bar(c,w*.025f,h*.06f,w*.24f,h*.085f,playerHp/playerMax,Color.rgb(200,43,70));
            bar(c,w*.025f,h*.095f,w*.24f,h*.115f,stamina/staminaMax,Color.rgb(78,162,91));
            text(c,bossTitles[boss],w/2,h*.155f,h*.027f,Color.rgb(213,183,145),Paint.Align.CENTER);
            fighter(c,w*.5f,h*.48f,boss==1?1.25f:boss==2?.82f:1,bossColors[boss],true,attackTimer>0);
            fighter(c,w*.5f,h*.79f,.72f,Color.rgb(55,70,83),false,playerAttack>0);
            float s=Math.min(w,h);
            lightButton.set(w-s*.18f,h-s*.38f,w-s*.04f,h-s*.24f);
            heavyButton.set(w-s*.31f,h-s*.52f,w-s*.17f,h-s*.38f);
            dodgeButton.set(w-s*.34f,h-s*.20f,w-s*.20f,h-s*.06f);
            blockButton.set(w-s*.48f,h-s*.37f,w-s*.34f,h-s*.23f);
            gearButton.set(w-s*.12f,h*.16f,w-s*.03f,h*.25f);
            nextButton.set(w-s*.12f,h*.27f,w-s*.03f,h*.36f);
            button(c,lightButton,"LIGHT",false);button(c,heavyButton,"HEAVY",false);button(c,dodgeButton,"DODGE",false);button(c,blockButton,"BLOCK",blocking);
            button(c,gearButton,"⚔",false);button(c,nextButton,"☠",false);
            p.setColor(Color.argb(90,90,66,52));c.drawCircle(s*.16f,h-s*.17f,s*.12f,p);
            p.setColor(Color.argb(140,180,137,95));c.drawCircle(s*.16f+moveX*s*.06f,h-s*.17f+moveY*s*.06f,s*.045f,p);
            text(c,weapons[weapon]+"  •  "+armors[armor],w*.025f,h*.15f,h*.025f,Color.LTGRAY,Paint.Align.LEFT);
            if(attackTimer>0){stroke.setStyle(Paint.Style.STROKE);stroke.setStrokeWidth(7);stroke.setColor(Color.YELLOW);c.drawCircle(w*.5f,h*.31f,h*.1f,stroke);stroke.setStyle(Paint.Style.FILL);}
            if(victory) overlay(c,w,h,"VICTORY","Πάτησε ☠ για τον επόμενο αντίπαλο");
            if(defeat) overlay(c,w,h,"DEFEATED","Πάτησε στο κέντρο για νέα προσπάθεια");
        }

        void fighter(Canvas c,float x,float y,float scale,int color,boolean enemy,boolean attacking){
            float h=getHeight();float u=h*.12f*scale;p.setColor(color);
            Path body=new Path();body.moveTo(x-u*.35f,y);body.lineTo(x-u*.45f,y-u*1.3f);body.lineTo(x-u*.25f,y-u*1.9f);body.lineTo(x+u*.25f,y-u*1.9f);body.lineTo(x+u*.45f,y-u*1.3f);body.lineTo(x+u*.35f,y);body.close();c.drawPath(body,p);
            p.setColor(Color.rgb(25,20,20));c.drawCircle(x,y-u*2.18f,u*.29f,p);
            stroke.setStyle(Paint.Style.STROKE);stroke.setStrokeWidth(u*.08f);stroke.setColor(enemy?Color.rgb(255,177,82):Color.rgb(215,170,93));
            c.drawLine(x+u*.25f,y-u*1.45f,x+u*(attacking?1.15f:.7f),y-u*(attacking?2.55f:2.3f),stroke);stroke.setStyle(Paint.Style.FILL);
        }

        void overlay(Canvas c,float w,float h,String title,String sub){p.setColor(Color.argb(190,0,0,0));c.drawRect(0,h*.3f,w,h*.7f,p);text(c,title,w/2,h*.48f,h*.1f,Color.WHITE,Paint.Align.CENTER);text(c,sub,w/2,h*.59f,h*.035f,Color.LTGRAY,Paint.Align.CENTER);}
        void bar(Canvas c,float l,float t,float r,float b,float q,int color){p.setColor(Color.rgb(28,17,16));c.drawRect(l,t,r,b,p);p.setColor(color);c.drawRect(l,t,l+(r-l)*Math.max(0,q),b,p);}
        void button(Canvas c,RectF r,String label,boolean on){p.setColor(on?Color.rgb(120,60,35):Color.rgb(49,34,29));c.drawOval(r,p);stroke.setStyle(Paint.Style.STROKE);stroke.setStrokeWidth(2);stroke.setColor(Color.rgb(150,95,60));c.drawOval(r,stroke);stroke.setStyle(Paint.Style.FILL);text(c,label,r.centerX(),r.centerY()+getHeight()*.012f,Math.min(r.width(),r.height())*.19f,Color.WHITE,Paint.Align.CENTER);}
        void text(Canvas c,String s,float x,float y,float size,int color,Paint.Align align){p.setShader(null);p.setStyle(Paint.Style.FILL);p.setTextSize(size);p.setTextAlign(align);p.setColor(color);c.drawText(s,x,y,p);}

        @Override public boolean onTouchEvent(android.view.MotionEvent e){
            float x=e.getX(),y=e.getY();int a=e.getActionMasked();
            if(a==MotionEvent.ACTION_DOWN){
                if(!started&&startButton.contains(x,y)){started=true;resetBoss();return true;}
                if(!started)return true;
                if(defeat&&y>getHeight()*.3f&&y<getHeight()*.7f){resetBoss();return true;}
                if(nextButton.contains(x,y)){boss=(boss+1)%bossNames.length;resetBoss();return true;}
                if(gearButton.contains(x,y)){weapon=(weapon+1)%weapons.length;armor=(armor+1)%armors.length;return true;}
                if(!running)return true;
                if(lightButton.contains(x,y))attack(false);
                else if(heavyButton.contains(x,y))attack(true);
                else if(dodgeButton.contains(x,y)&&stamina>=25){stamina-=25;dodgeTimer=.48f;}
                else if(blockButton.contains(x,y)){blocking=true;}
                else {activePointer=e.getPointerId(0);setMove(x,y);}
            } else if(a==MotionEvent.ACTION_MOVE&&activePointer>=0){int i=e.findPointerIndex(activePointer);if(i>=0)setMove(e.getX(i),e.getY(i));}
            else if(a==MotionEvent.ACTION_UP||a==MotionEvent.ACTION_CANCEL){blocking=false;activePointer=-1;moveX=moveY=0;}
            invalidate();return true;
        }
        void attack(boolean heavy){if(playerAttack>0)return;float cost=weaponCost[weapon]*(heavy?1.65f:1);if(stamina<cost)return;stamina-=cost;playerAttack=heavy?.72f:.4f;}
        void setMove(float x,float y){float s=Math.min(getWidth(),getHeight()),cx=s*.16f,cy=getHeight()-s*.17f;moveX=Math.max(-1,Math.min(1,(x-cx)/(s*.12f)));moveY=Math.max(-1,Math.min(1,(y-cy)/(s*.12f)));}
    }
}
