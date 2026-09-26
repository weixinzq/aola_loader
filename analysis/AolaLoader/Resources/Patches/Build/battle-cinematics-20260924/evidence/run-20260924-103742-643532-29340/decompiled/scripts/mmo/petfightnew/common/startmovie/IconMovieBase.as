package mmo.petfightnew.common.startmovie
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.manager.FightMovieManager;
   
   public class IconMovieBase extends MovieClip
   {
      
      private var mcContainer:Sprite;
      
      private var isMySide:Boolean = true;
      
      private var _icon:FightIconBase;
      
      public function IconMovieBase()
      {
         super();
         this.gotoAndStop(1);
      }
      
      public function init(param1:PlayerBattleInfo, param2:Boolean) : void
      {
         var mv:MovieClip = null;
         var info:PlayerBattleInfo = param1;
         var isMySide:Boolean = param2;
         this.isMySide = isMySide;
         if(isMySide)
         {
            if(info.PMMasterId > 0)
            {
               this._icon = new MyIcon(info);
            }
            else
            {
               this._icon = new MyAIIcon(info);
            }
         }
         else if(info.PMMasterId > 0 || FightData.instance.challengeNpcId > 0)
         {
            this._icon = new VsIcon(info);
         }
         else
         {
            this._icon = new AIIcon(info);
            this._icon.y -= 50;
         }
         mv = this;
         FightMovieManager.instance.addMovie(mv);
         this.addFrameScript(8,function():void
         {
            mcContainer = getChildByName("container") as Sprite;
            mcContainer.addChild(icon);
         },totalFrames - 1,function():void
         {
            FightMovieManager.instance.removeMovie(mv);
            stop();
         });
         this.gotoAndPlay(1);
      }
      
      public function get icon() : FightIconBase
      {
         return this._icon;
      }
   }
}

