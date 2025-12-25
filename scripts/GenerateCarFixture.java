import baseline.*;
import org.agrona.concurrent.UnsafeBuffer;

import java.io.FileOutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

public class GenerateCarFixture
{
    public static void main(final String[] args) throws Exception
    {
        final String outputPath = args.length > 0 ? args[0] : "test/java-fixtures/car-example.bin";
        final ByteBuffer byteBuffer = ByteBuffer.allocate(4096);
        final UnsafeBuffer directBuffer = new UnsafeBuffer(byteBuffer);

        final MessageHeaderEncoder messageHeaderEncoder = new MessageHeaderEncoder();
        final CarEncoder carEncoder = new CarEncoder();

        final int length = encode(carEncoder, directBuffer, messageHeaderEncoder);
        final byte[] bytes = new byte[length];
        byteBuffer.position(0);
        byteBuffer.get(bytes, 0, length);

        try (FileOutputStream out = new FileOutputStream(outputPath))
        {
            out.write(bytes);
        }
    }

    private static int encode(
        final CarEncoder car, final UnsafeBuffer directBuffer, final MessageHeaderEncoder messageHeaderEncoder)
    {
        final byte[] vehicleCode = "abcdef".getBytes(StandardCharsets.US_ASCII);
        final byte[] manufacturerCode = "123".getBytes(StandardCharsets.US_ASCII);
        final byte[] manufacturer = "Honda".getBytes(StandardCharsets.UTF_8);
        final byte[] model = "Civic VTi".getBytes(StandardCharsets.UTF_8);
        final byte[] activationCode = "abcdef".getBytes(StandardCharsets.US_ASCII);

        car.wrapAndApplyHeader(directBuffer, 0, messageHeaderEncoder)
            .serialNumber(1234)
            .modelYear(2013)
            .available(BooleanType.T)
            .code(Model.A)
            .putVehicleCode(vehicleCode, 0);

        car.putSomeNumbers(1, 2, 3, 4);

        car.extras()
            .clear()
            .cruiseControl(true)
            .sportsPack(true)
            .sunRoof(false);

        car.engine()
            .capacity(2000)
            .numCylinders((short)4)
            .putManufacturerCode(manufacturerCode, 0)
            .efficiency((byte)35)
            .boosterEnabled(BooleanType.T)
            .booster().boostType(BoostType.NITROUS).horsePower((short)200);

        car.fuelFiguresCount(3)
            .next().speed(30).mpg(35.9f).usageDescription("Urban Cycle")
            .next().speed(55).mpg(49.0f).usageDescription("Combined Cycle")
            .next().speed(75).mpg(40.0f).usageDescription("Highway Cycle");

        final CarEncoder.PerformanceFiguresEncoder figures = car.performanceFiguresCount(2);
        figures.next()
            .octaneRating((short)95)
            .accelerationCount(3)
            .next().mph(30).seconds(4.0f)
            .next().mph(60).seconds(7.5f)
            .next().mph(100).seconds(12.2f);
        figures.next()
            .octaneRating((short)99)
            .accelerationCount(3)
            .next().mph(30).seconds(3.8f)
            .next().mph(60).seconds(7.1f)
            .next().mph(100).seconds(11.8f);

        car.manufacturer(new String(manufacturer, StandardCharsets.UTF_8))
            .putModel(model, 0, model.length)
            .putActivationCode(activationCode, 0, activationCode.length);

        return MessageHeaderEncoder.ENCODED_LENGTH + car.encodedLength();
    }
}
