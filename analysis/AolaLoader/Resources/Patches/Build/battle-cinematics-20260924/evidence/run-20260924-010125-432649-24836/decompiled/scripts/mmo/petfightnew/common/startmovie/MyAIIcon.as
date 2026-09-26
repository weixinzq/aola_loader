package mmo.petfightnew.common.startmovie
{
   import flash.text.TextField;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.FightData;
   
   public class MyAIIcon extends FightIconBase
   {
      
      private var raceIdToName:Object = {
         10089:{"name":"锐角羊龙"},
         10186:{"name":"维克"},
         10299:{"name":"哈德"},
         70105:{"name":"神武月"},
         70103:{"name":"赤月"},
         70109:{"name":"炎风"},
         30317:{"name":"天使莱特"},
         10323:{"name":"拉贝尔"},
         40105:{"name":"神武月"},
         40111:{"name":"战无炎"},
         70111:{"name":"战无炎"},
         10091:{"name":"木面仔"},
         10653:{"name":"飞天独角兽"},
         10675:{"name":"白天鹅"},
         20682:{"name":"黑夜童心"},
         30731:{"name":"修罗"},
         50731:{"name":"修罗"},
         10849:{"name":"神射手糖糖"},
         20846:{"name":"小白吐"},
         10894:{"name":"亚伦"},
         10896:{"name":"贝琪"},
         20895:{"name":"利克亚伦"},
         20897:{"name":"百变贝琪"},
         10915:{"name":"泽时"},
         10914:{"name":"泽分"},
         10731:{"name":"修罗"},
         10967:{"name":"巨岩"},
         10980:{"name":"路比比"},
         40860:{"name":"关羽"},
         40955:{"name":"张飞"},
         21081:{"name":"奇奇"},
         51082:{"name":"奥奇"},
         11122:{"name":"狼王"},
         161082:{"name":"奥奇"},
         11182:{"name":"黑皮"},
         11183:{"name":"捣蛋黑皮"},
         11184:{"name":"飞灵"},
         11227:{"name":"茜点"},
         10563:{"name":"蓝宝星"},
         21259:{"name":"友人契约书"},
         31282:{"name":"施瓦辛格"},
         31259:{"name":"友人契约书"},
         31267:{"name":"多古拉伯爵"},
         190147:{"name":"芭芭拉"},
         190653:{"name":"小南姐姐"},
         190901:{"name":"贝鲁特"},
         190768:{"name":"泰勒"},
         190186:{"name":"维克"},
         190323:{"name":"拉贝尔"},
         21320:{"name":"伊泽"},
         21322:{"name":"迦娜"},
         21286:{"name":"波波嘟"},
         61122:{"name":"狼王迪洛斯"},
         61135:{"name":"赤翼魔龙王"},
         61142:{"name":"幻灵"},
         1379:{"name":"斯巴达"},
         1409:{"name":"铁迪"},
         81240:{"name":"乐天"},
         81227:{"name":"茜点"},
         81257:{"name":"雏菊仙子"},
         81265:{"name":"多米力"},
         81312:{"name":"海琪琪"},
         231473:{"name":"圣灵星诺"},
         51538:{"name":"炼狱战狮"},
         51539:{"name":"炼狱狮王"},
         51541:{"name":"魔戒邪灵"},
         21556:{"name":"斑比"},
         11577:{"name":"王者蒙奇"},
         1615:{"name":"太白"},
         10328:{"name":"SR战士"},
         11645:{"name":"圣盾"},
         61754:{"name":"炎王•火龙态"},
         61777:{"name":"帝卡•影龙态"},
         61825:{"name":"明王•巨龙态"},
         61873:{"name":"冰罗皇冰龙态"},
         81896:{"name":"圣•天伊"},
         80731:{"name":"修罗"},
         120105:{"name":"神武月"},
         181122:{"name":"狼王迪洛斯"},
         80728:{"name":"凯撒"},
         120111:{"name":"战无炎"},
         101124:{"name":"夜王狄米特"},
         31854:{"name":"诺伊特"},
         21726:{"name":"利威尔"},
         20003:{"name":"大师兔"},
         11200:{"name":"魔剑守卫"},
         11403:{"name":"暗影兽"},
         70006:{"name":"爆焰吉拉"},
         20009:{"name":"露西亚"},
         11120:{"name":"冰刃侠"},
         41854:{"name":"诺伊特"},
         31726:{"name":"利威尔"},
         32027:{"name":"裂空菲洛"}
      };
      
      private const nameArr:Array = ["守护"];
      
      public function MyAIIcon(param1:PlayerBattleInfo)
      {
         super(param1);
      }
      
      override protected function initBalls() : void
      {
      }
      
      override protected function initIcon() : void
      {
      }
      
      override protected function initName() : void
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc1_:int = int(PetBriefInfo(this.info.myPets[0]).raceId);
         var _loc2_:TextField = this.getChildByName("txtName") as TextField;
         if(this.raceIdToName[_loc1_] != null)
         {
            _loc2_.text = this.raceIdToName[_loc1_].name;
         }
         else
         {
            _loc3_ = FightData.instance.getNextAiName();
            if(_loc3_ == null)
            {
               _loc4_ = Math.floor(Math.random() * this.nameArr.length);
               _loc2_.text = this.nameArr[_loc4_];
            }
            else
            {
               _loc2_.text = _loc3_;
            }
         }
      }
   }
}

